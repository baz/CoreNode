//
//  NodeJSFunction.m
//  ObjectiveNode
//
//  Created by Basil Shkara on 13/05/11.
//  Copyright 2011 Neat.io Pty Ltd. All rights reserved.
//

#import "NodeJSFunction.h"
#import "node_interface.h"
#import "node_ns_additions.h"
#import "common.h"

using namespace v8;

static std::map<id, Persistent<Value> > valueCache;


@implementation NodeJSFunction


- (void)dealloc {
  function_.Dispose();
  function_.Clear();

  std::map<id, Persistent<Value> >::iterator it;
  for (it = valueCache.begin(); it != valueCache.end(); it++) {
    Persistent<Value> v = it->second;
    v.Dispose();
    v.Clear();
    valueCache.erase(it->first);
  }
  valueCache.clear();

  [super dealloc];
}

- (id)retain {
  return [super retain];
}

- (void)release {
   [super release];
}

- (void)setV8Function:(v8::Local<v8::Function>)function {
  function_ = Persistent<Function>::New(function);
}

- (void)invokeWithArguments:(id)argument, ... {
  static const int argcmax = 16;
  Handle<Value> *argv = new Handle<Value>[argcmax];
  int argc = 0;
  if (argument) {
    va_list valist;
    va_start(valist, argument);
    for (id arg = argument; arg != nil; arg = va_arg(valist, id)) {
      if (valueCache.count(arg)) {
        argv[argc] = valueCache[arg];
      } else {
        Local<Value> v = [arg v8Value];
        argv[argc] = v;
        // Cache for next time
        valueCache[arg] = Persistent<Value>::New(v);
      }
      argc++;
    }
    va_end(valist);
  }

  NodePerformInNode(^(NodeReturnBlock returnCallback) {
    TryCatch tryCatch;
    if (function_->IsFunction()) {
      Local<Function> fun = Function::Cast(*function_);
      fun->Call(Context::GetCurrent()->Global(), argc, argv);
      delete argv;
      if (tryCatch.HasCaught()) {
        String::Utf8Value trace(tryCatch.StackTrace());
        WLOG("Error occurred whilst calling NodeJSFunction: %s", *trace ? *trace : "(no trace)");
      }
    }
  });
}


@end
