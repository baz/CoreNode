// Copyright (c) 2010-2011, Rasmus Andersson. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

#import <Cocoa/Cocoa.h>
#import <dispatch/dispatch.h>
#import <node.h>
#import "ObjectiveNode.h"
#include <map>
#include <vector>
#include <string>

class NodeIOEntry;
class NodeBlockFun;
namespace kod { class ExternalUTF16String; }

typedef void (^NodeReturnBlock)(NodeCallbackBlock, NSError*, NSArray*);
typedef void (^NodePerformBlock)(NodeReturnBlock);
typedef void (^NodeFunctionBlock)(const v8::Arguments& args);

// initialize (must be called from node)
void NodeInitNode();

// perform |block| in the node runtime
void NodePerformInNode(NodePerformBlock block);
void NodeEnqueueIOEntry(NodeIOEntry *entry);

/*!
 * Invoke |fun| on |target| passing |argc| number of arguments in |argv|.
 * If |arg0| is set, that value will be used as the first argument and |argc|
 * increased by 1.
 */
v8::Handle<v8::Value> KNodeCallFunction(v8::Handle<v8::Object> target,
                                        v8::Handle<v8::Function> fun,
                                        int argc, id *argv,
                                        v8::Local<v8::Value> *arg0=NULL);

// invoke a named function inside node
void nodeInvokeFunction(const char *functionName, const char *objectName, NSArray *args, NodeCallbackBlock callback);

void nodeInvokeFunction(const char *functionName, const char *objectName, NodeCallbackBlock callback);

// emit an event on the specified object, passing args
void nodeEmitEventv(const char *eventName, const char *objectName, int argc, id *argv);

// emit an event on the specified object, passing nil-terminated list of args
void nodeEmitEvent(const char *eventName, const char *objectName, ...);

// perform |block| in the kod runtime (queue defaults to main thread)
static inline void NodePerformInObjectiveNode(NodeCallbackBlock block,
                                     NSError *err=nil,
                                     NSArray *args=nil,
                                     dispatch_queue_t queue=NULL) {
  if (!queue) queue = dispatch_get_main_queue();
  dispatch_async(queue, ^{ block(err, args); });
}

// inject a custom Node module into the global context
void injectNodeModule(void(*init_module)(v8::Handle<v8::Object> target), const char *module_name, bool root);

// allow specified class to be proxied through to Node for interaction of setters/getters
void initializeObjectProxy(const char *className, const char *sourceClassName);

// maintain a persistent pointer to a node object in a global map
void registerNodeObject(const char *name, v8::Persistent<v8::Object> object);

// dispose of a previously persistent object
void unregisterNodeObject(const char *name);

// unregister all objects
void unregisterAllNodeObjects();

// Input/Output queue entry base class
class NodeIOEntry {
 public:
  NodeIOEntry() {}
  virtual ~NodeIOEntry() {}
  virtual void perform() { delete this; }
  NodeIOEntry *next_;
};



// Invocation transaction I/O queue entry
class KNodeTransactionalIOEntry : public NodeIOEntry {
 public:
  KNodeTransactionalIOEntry(NodePerformBlock block, dispatch_queue_t returnDispatchQueue=NULL) {
    performBlock_ = [block copy];
    if (returnDispatchQueue) {
      returnDispatchQueue_ = returnDispatchQueue;
      dispatch_retain(returnDispatchQueue_);
    } else {
      returnDispatchQueue_ = NULL;
    }
  }

  virtual ~KNodeTransactionalIOEntry() {
    [performBlock_ release];
    if (returnDispatchQueue_) {
      dispatch_release(returnDispatchQueue_);
    }
    returnDispatchQueue_ = NULL;
  }

  void perform() {
    // maintain a weak reference because the queue may be released
	__block dispatch_queue_t blockReturnQueue = returnDispatchQueue_;
    performBlock_(^(NodeCallbackBlock callback, NSError *err, NSArray *args) {
      if (callback) {
        // queue may be released by now
        // invoke the original ObjC callback block that was provided by the caller
        NodePerformInObjectiveNode(callback, err, args, blockReturnQueue);
      }
    });
    // call super which will delete this instance
    NodeIOEntry::perform();
  }

 protected:
  NodePerformBlock performBlock_;
  dispatch_queue_t returnDispatchQueue_;
};


// Invokes funcName on target passing arguments
class NodeInvocationIOEntry : public NodeIOEntry {
 public:
  NodeInvocationIOEntry(v8::Handle<v8::Object> target, const char *funcName, int argc=0, id *argv=NULL);
  NodeInvocationIOEntry(v8::Handle<v8::Object> target, const char *funcName, int argc, v8::Handle<v8::Value> argv[]);
  virtual ~NodeInvocationIOEntry();
  void perform();
 protected:
  char *funcName_;
  v8::Persistent<v8::Object> target_;
  int argc_;
  v8::Persistent<v8::Value> *argv_;
};


// Event I/O queue entry
class NodeEventIOEntry : public NodeIOEntry {
 public:
  NodeEventIOEntry(const char *name, const char *objectName, int argc, id *argv);
  virtual ~NodeEventIOEntry();
  void perform();
 protected:
  char *name_;
  char *objectName_;
  int argc_;
  id *argv_;
};


// -------------------

class NodeBlockFun {
  NodeFunctionBlock block_;
  v8::Persistent<v8::Function> fun_;
 public:
  NodeBlockFun(NodeFunctionBlock block);
  ~NodeBlockFun();
  inline v8::Local<v8::Value> function() { return *fun_; }
  static v8::Handle<v8::Value> InvocationProxy(const v8::Arguments& args);
 protected:
  static void WeakCallback (v8::Persistent<v8::Value> value, void *data);
};

// -------------------

class ARPoolScope {
 public:
  NSAutoreleasePool *pool_;
  ARPoolScope() { pool_ = [NSAutoreleasePool new]; }
  ~ARPoolScope() { [pool_ drain]; pool_ = nil; }
};

// -------------------

static inline v8::Persistent<v8::Object>* NodePersistentObjectUnwrap(
    const v8::Local<v8::Value> &v) {
  v8::Persistent<v8::Object> *pobj = new v8::Persistent<v8::Object>();
  *pobj = v8::Persistent<v8::Object>::New(v8::Local<v8::Object>::Cast(v));
  return pobj;
}

static inline v8::Persistent<v8::Object>* NodePersistentObjectUnwrap(void *data) {
  v8::Persistent<v8::Object> *pobj = reinterpret_cast<v8::Persistent<v8::Object>*>(data);
  assert((*pobj)->IsObject());
  return pobj;
}

static inline void NodePersistentObjectDestroy(v8::Persistent<v8::Object> *pobj) {
  pobj->Dispose();
  delete pobj;
}

