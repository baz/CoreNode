// Copyright (c) 2010-2011, Rasmus Andersson. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

#import "common.h"
#import "node_interface.h"
#import "node_ns_additions.h"
#import "ExternalUTF16String.h"
#import <node.h>
#import <node_events.h>
#import <ev.h>
#import <libkern/OSAtomic.h>
#import "NodeObjectProxy.h"

using namespace v8;

void DummyFunction() { }
#define KnownAddress ((char *) ::DummyFunction)
#define cxx_offsetof(type, member) \
  (((char *) &((type *) KnownAddress)->member) - KnownAddress)

// ----------------------

// queue with entries of type NodeIOEntry*
static OSQueueHead KNodeIOInputQueue;

// ev notifier
static ev_async KNodeIOInputQueueNotifier;

// Map to hold registered objects
static std::map<std::string, v8::Persistent<v8::Object> > nodeObjectMap;

static v8::Persistent<v8::Object> objectiveNodeModule;

// max number of entries to dequeue in one flush
#define KNODE_MAX_DEQUEUE 100

// ----------------------


// Triggered when there are stuff on inputQueue_
static void _QueueNotification(OSQueueHead *queue, ev_async *watcher, int revents) {
  HandleScope scope;
  //NSLog(@"InputQueueNotification");

  // enumerate queue
  // since we use a LIFO queue for atomicity, we need to reverse the order
  NodeIOEntry* entries[KNODE_MAX_DEQUEUE+1];
  int i = 0;
  NodeIOEntry* entry;
  while ( (entry = (NodeIOEntry*)OSAtomicDequeue(
           queue, cxx_offsetof(NodeIOEntry, next_)))
          && (i < KNODE_MAX_DEQUEUE) ) {
    //NSLog(@"dequeued NodeIOEntry@%p", entry);
    entries[i++] = entry;
  }
  entries[i] = NULL; // sentinel

  // perform entries in the order they where queued
  while (i && (entry = entries[--i])) {
    entry->perform();
    // Note: |entry| is invalid beyond this point as it probably deleted itself
  }
}


// Triggered when there are stuff on inputQueue_
static void InputQueueNotification(EV_P_ ev_async *watcher, int revents) {
  _QueueNotification(&KNodeIOInputQueue, watcher, revents);
}


static void _freePersistentArgs(int argc, Persistent<Value> *argv) {
  for (int i=0; i<argc; ++i) {
    Persistent<Value> v = argv[i];
    if (v.IsEmpty()) continue;
    v.Dispose();
    v.Clear();
  }
  if (argv) delete argv;
}


NodeBlockFun::NodeBlockFun(NodeFunctionBlock block) {
  block_ = [block copy];
  Local<FunctionTemplate> t = FunctionTemplate::New(&NodeBlockFun::InvocationProxy, External::Wrap(this));
  fun_ = Persistent<Function>::New(t->GetFunction());
}

NodeBlockFun::~NodeBlockFun() {
  [block_ release];
  if (!fun_.IsEmpty()) {
    fun_.Dispose();
    fun_.Clear();
  }
}

// static
// this will be invoked when the JS function executes the callback
// unwrap the arguments that come back to retrieve the original NodeBlockFun instance
v8::Handle<Value> NodeBlockFun::InvocationProxy(const Arguments& args) {
  Local<Value> data = args.Data();
  assert(!data.IsEmpty());
  NodeBlockFun* blockFun = (NodeBlockFun*)External::Unwrap(data);
  assert(((void*)blockFun->block_) != NULL);
  if (blockFun->block_) {
    blockFun->block_(args);
  }
  delete blockFun;
  return Undefined();
}


static bool _invokeJSFunction(const char *functionName, const char *objectName, int argc, v8::Handle<v8::Value> argv[]) {
  bool success = false;
  if (!nodeObjectMap.empty()) {
    Persistent<Object> object = nodeObjectMap[std::string(objectName)];
    Local<Value> v = object->Get(String::New(functionName));
    if (v->IsFunction()) {
      Local<Function> fun = Function::Cast(*v);
      fun->Call(object, argc, argv);
      success = true;
    }
  }

  return success;
}


static id _invokeJSFunctionSync(const char *functionName, const char *objectName, int argc, v8::Handle<v8::Value> argv[]) {
  HandleScope scope;
  id retVal = nil;
  if (!nodeObjectMap.empty()) {
    Persistent<Object> object = nodeObjectMap[std::string(objectName)];
    Local<Value> v = object->Get(String::New(functionName));
    if (v->IsFunction()) {
      Local<Function> fun = Function::Cast(*v);
      Local<Value> v8Value = fun->Call(object, argc, argv);
      retVal = [NSObject fromV8Value:v8Value];
    }
  }

  return retVal;
}


v8::Handle<v8::Value> KNodeCallFunction(v8::Handle<Object> target,
                                        v8::Handle<Function> fun,
                                        int argc, id *objc_argv,
                                        v8::Local<Value> *arg0/*=NULL*/) {
  v8::HandleScope scope;

  // increment arg count if we got a firstArgAsString
  if (arg0)
    ++argc;

  // allocate list of arguments
  Local<Value> *argv = new Local<Value>[argc];

  // add firstArgAsString
  if (arg0)
    argv[0] = *arg0;

  // add all objc args
  int i = arg0 ? 1 : 0, L = argc;
  for (; i<L; ++i) {
    id arg = objc_argv[i-(arg0 ? 1 : 0)];
    if (arg) {
      argv[i] = Local<Value>::New([arg v8Value]);
    } else {
      argv[i] = *v8::Null();
    }
  }

  // invoke function
  Local<Value> ret = fun->Call(target, argc, argv);
  delete argv;

  return scope.Close(ret);
}


void nodeInvokeFunction(const char *functionName, const char *objectName, NSArray *args, NodeCallbackBlock callback) {
  // call from kod-land
  //DLOG("[knode] 1 calling node from kod");
  char *function = strdup(functionName);
  char *object = strdup(objectName);
  NodePerformInNode(^(NodeReturnBlock returnCallback) {
    //DLOG("[knode] 1 called in node");
    //DLOG("[knode] 1 calling kod from node");
    v8::HandleScope scope;

    // create a JS function which is the last callback argument
    // this proxy function object wraps an ObjC block which will be pulled out and invoked when the JS function calls back
    __block BOOL blockFunDidExecute = NO;
    NodeBlockFun *blockFun = new NodeBlockFun(^(const v8::Arguments& args){
      // pass args to callback (convert to cocoa first)
      NSArray *args2 = nil;
      NSError *err = nil;
      // check if first arg is an object and if so, treat it as an error
      if (args.Length() > 0) {
        Local<Value> v = args[0];
        if (v->IsString() || v->IsObject()) {
          String::Utf8Value utf8pch(v->ToString());
          err = [NSError nodeErrorWithFormat:@"%s", *utf8pch];
        }
        if (args.Length() > 1) {
          args2 = [NSMutableArray arrayWithCapacity:args.Length()-1];
          for (int i = 1; i < args.Length(); ++i)
            [(NSMutableArray*)args2 addObject:[NSObject fromV8Value:args[i]]];
        }
      }
      returnCallback(callback, err, args2);
      blockFunDidExecute = YES;
    });

    // pass all arguments to the JS function we intend to invoke
    TryCatch tryCatch;
    Local<Value> fun = blockFun->function();
    bool didFindAndCallFun;
    NSUInteger argc = args ? args.count : 0;
    if (argc != 0) {
      // passing the block function as the last parameter
      argc++;
      Local<Value> *argv = new Local<Value>[argc];
      NSUInteger i = 0;
      for (; i<argc - 1; i++) {
        argv[i] = [[args objectAtIndex:i] v8Value];
        // TODO Automatically convert any object into a JS object with key-value pairs.
        // This means the new object will just be a dumb representation...turn it into a proxy object where any change in JS land makes the change in ObjC land.
      }
      argv[i] = fun;
      didFindAndCallFun = _invokeJSFunction(function, object, (unsigned int) argc, argv);
      delete argv;
    } else {
      didFindAndCallFun = _invokeJSFunction(function, object, 1, &fun);
    }

    NSError *error = nil;
    if (tryCatch.HasCaught()) {
      error = [NSError nodeErrorWithTryCatch:tryCatch];
    } else if (!didFindAndCallFun) {
      error = [NSError nodeErrorWithFormat:@"Unknown method '%s'", function];
    }
    free(function);
    free(object);

    if (error) {
      DLOG("[knode] error while calling into node: %@", error);
      if (!blockFunDidExecute) {
        // dispose of block function
        delete blockFun;
        // invoke callback with error
        returnCallback(callback, error, nil);
      }
    }
  });
}


void nodeInvokeFunction(const char *functionName, const char *objectName, NodeCallbackBlock callback) {
  nodeInvokeFunction(functionName, objectName, nil, callback);
}


id nodeInvokeFunctionSync(const char *functionName, const char *objectName, NSArray *args) {
  HandleScope scope;
  NSUInteger argc = [args count];
  Local<Value> *argv = new Local<Value>[argc];
  for (int i=0; i<[args count]; i++) {
    argv[i] = [[args objectAtIndex:i] v8Value];
  }
  id retVal = _invokeJSFunctionSync(functionName, objectName, (unsigned int) argc, argv);
  delete argv;

  return retVal;
}


void nodeEmitEventv(const char *eventName, const char *objectName, int argc, id *argv) {
  NodeEventIOEntry *entry = new NodeEventIOEntry(eventName, objectName, argc, argv);
  NodeEnqueueIOEntry(entry);
}


void nodeEmitEvent(const char *eventName, const char *objectName, ...) {
  static const int argcmax = 16;
  va_list valist;
  va_start(valist, objectName);
  id argv[argcmax];
  id arg;
  int argc = 0;
  while ((arg = va_arg(valist, id)) && argc < argcmax) {
    argv[argc++] = arg;
  }
  va_end(valist);
  nodeEmitEventv(eventName, objectName, argc, argv);
}


void NodeInitNode() {
  // setup notifiers
  KNodeIOInputQueueNotifier.data = NULL;
  ev_async_init(&KNodeIOInputQueueNotifier, &InputQueueNotification);
  ev_async_start(EV_DEFAULT_UC_ &KNodeIOInputQueueNotifier);

  // stuff might have been queued before we initialized, so trigger a dequeue
  ev_async_send(EV_DEFAULT_UC_ &KNodeIOInputQueueNotifier);
}


static void _NodeEnqueueEntry(OSQueueHead *queue, ev_async *asyncWatcher, NodeIOEntry *entry) {
  OSAtomicEnqueue(queue, entry, cxx_offsetof(NodeIOEntry, next_));
  ev_async_send(EV_DEFAULT_UC_ asyncWatcher);
}


void NodeEnqueueIOEntry(NodeIOEntry *entry) {
  _NodeEnqueueEntry(&KNodeIOInputQueue, &KNodeIOInputQueueNotifier, entry);
}


void NodePerformInNode(NodePerformBlock block) {
  dispatch_queue_t queue = dispatch_get_current_queue();
  NodeIOEntry *entry = new KNodeTransactionalIOEntry(block, queue);
  NodeEnqueueIOEntry(entry);
}

static void _bindModule(const char *name, v8::Handle<Object> module) {
  Local<Value> bindingsObject = objectiveNodeModule->Get(String::New("binding"));
  if (bindingsObject->IsObject()) {
    Local<Object>::Cast(bindingsObject)->Set(String::New(name), module);
  }
}

void injectNodeModule(void(*init_module)(v8::Handle<v8::Object> target), const char *module_name, bool root) {
  v8::HandleScope scope;
  Local<FunctionTemplate> function_template = FunctionTemplate::New();
  node::EventEmitter::Initialize(function_template);
  Persistent<Object> function_instance = Persistent<Object>::New(function_template->GetFunction()->NewInstance());
  init_module(function_instance);
  if (root) {
    // Special case for the objective_node module
    Local<Object> global = v8::Context::GetCurrent()->Global();
    global->Set(String::New(module_name), function_instance);
    objectiveNodeModule = function_instance;
  } else {
    // Set via binding object on objective_node module to prevent polluting the global namespace
    _bindModule(module_name, function_instance);
  }
}

void initializeObjectProxy(const char *className) {
  v8::HandleScope scope;
  Local<FunctionTemplate> function_template = FunctionTemplate::New();
  node::EventEmitter::Initialize(function_template);
  Persistent<Object> function_instance = Persistent<Object>::New(function_template->GetFunction()->NewInstance());
  NodeObjectProxy::Initialize(function_instance, String::NewSymbol(className));

  _bindModule(className, function_instance);
}

void registerNodeObject(const char *name, Persistent<Object> object) {
  v8::HandleScope scope;
  if (!object->IsObject()) return;
  unregisterNodeObject(name);
  nodeObjectMap[std::string(name)] = object;
}

void unregisterNodeObject(const char *name) {
  if (!nodeObjectMap.empty()) {
    Persistent<Object> object = nodeObjectMap[std::string(name)];
    object.Clear();
    object.Dispose();
  }
}

void unregisterAllNodeObjects() {
  if (!nodeObjectMap.empty()) {
    std::map<std::string, v8::Persistent<v8::Object> >::iterator it;
    for (it = nodeObjectMap.begin(); it != nodeObjectMap.end(); it++) {
      unregisterNodeObject(it->first.c_str());
    }
  }
}


// ---------------------------------------------------------------------------

NodeInvocationIOEntry::NodeInvocationIOEntry(v8::Handle<Object> target,
                                               const char *funcName,
                                               int argc, id *argv) {
  v8::HandleScope scope;
  target_ = Persistent<Object>::New(target);
  funcName_ = strdup(funcName);
  argc_ = argc;
  if (argc_ == 0) {
    argv_ = NULL;
  } else {
    argv_ = new Persistent<Value>[argc_];
    for (int i = 0; i<argc_; ++i) {
      argv_[i] = Persistent<Value>::New([argv[i] v8Value]);
    }
  }
}


NodeInvocationIOEntry::NodeInvocationIOEntry(v8::Handle<Object> target,
                                               const char *funcName,
                                               int argc,
                                               v8::Handle<Value> argv[]) {
  v8::HandleScope scope;
  target_ = Persistent<Object>::New(target);
  funcName_ = strdup(funcName);
  argc_ = argc;
  if (argc_ == 0) {
    argv_ = NULL;
  } else {
    argv_ = new Persistent<Value>[argc_];
    for (int i = 0; i<argc_; ++i) {
      argv_[i] = Persistent<Value>::New(argv[i]);
    }
  }
}


NodeInvocationIOEntry::~NodeInvocationIOEntry() {
  if (!target_.IsEmpty()) {
    target_.Dispose();
    target_.Clear();
  }
  _freePersistentArgs(argc_, argv_);
  if (funcName_) {
    free(funcName_);
  }
}


void NodeInvocationIOEntry::perform() {
  v8::HandleScope scope;
  DLOG("NodeInvocationIOEntry::perform()");
  if (!target_.IsEmpty()) {
    Local<Value> v = target_->Get(String::New(funcName_));
    if (v->IsFunction()) {
      DLOG("NodeInvocationIOEntry::perform() invoke '%s' with %d arguments",
           funcName_, argc_);
      Local<Function> fun = Local<Function>::Cast(v);
      Local<Value> ret = fun->Call(target_, argc_, argv_);
    }
  }
  NodeIOEntry::perform();
}


// ---------------------------------------------------------------------------

NodeEventIOEntry::NodeEventIOEntry(const char *name, const char *objectName, int argc, id *argv) {
  kassert(name != NULL);
  name_ = strdup(name);
  objectName_ = strdup(objectName);
  argc_ = argc;
  argv_ = new id[argc];
  for (int i = 0; i<argc_; ++i) {
    argv_[i] = [argv[i] retain];
  }
}


NodeEventIOEntry::~NodeEventIOEntry() {
  for (int i = 0; i<argc_; ++i) {
    [argv_[i] release];
  }
  delete argv_; argv_ = NULL;
  free(name_); name_ = NULL;
  free(objectName_); objectName_ = NULL;
}


void NodeEventIOEntry::perform() {
  v8::HandleScope scope;
  if (!nodeObjectMap.empty()) {
    Persistent<Object> object = nodeObjectMap[std::string(objectName_)];
    Local<Value> emitFunction = object->Get(String::New("emit"));
    if (emitFunction->IsFunction()) {
      Local<Value> eventName = Local<Value>::New(String::NewSymbol(name_));
      KNodeCallFunction(object, Local<Function>::Cast(emitFunction), argc_, argv_, &eventName);
    }
  }
  NodeIOEntry::perform();
}
// vim: expandtab:ts=2:sw=2
