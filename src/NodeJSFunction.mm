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


@implementation NodeJSFunction


- (void)dealloc {
  function_.Dispose();
  function_.Clear();

  std::map<id, Persistent<Value> >::iterator it;
  for (it = self->valueCache_.begin(); it != self->valueCache_.end(); it++) {
    Persistent<Value> v = it->second;
    v.Dispose();
    v.Clear();
    self->valueCache_.erase(it->first);
  }
  self->valueCache_.clear();

  [super dealloc];
}

- (void)setV8Function:(v8::Local<v8::Function>)function {
  function_ = Persistent<Function>::New(function);
}

- (void)invokeWithArguments:(id)argument, ... {
  NSMutableArray *arguments = [NSMutableArray arrayWithCapacity:0];
  if (argument) {
    va_list valist;
    va_start(valist, argument);
    for (id arg = argument; arg != nil; arg = va_arg(valist, id)) {
      [arguments addObject:arg];
    }
    va_end(valist);
  }

  NodePerformInNode(^(NodeReturnBlock returnCallback) {
    HandleScope scope;
    Handle<Value> *argv = new Handle<Value>[[arguments count]];
    int argc = 0;
    for (id arg in arguments) {
      if (self->valueCache_.count(arg)) {
        argv[argc] = self->valueCache_[arg];
      } else {
        Local<Value> v = [arg v8Value];
        argv[argc] = v;
        // Cache for next time
        self->valueCache_[arg] = Persistent<Value>::New(v);
      }
      argc++;
    }

    TryCatch tryCatch;
    if (function_->IsFunction()) {
      function_->Call(Context::GetCurrent()->Global(), argc, argv);
      delete argv;
      if (tryCatch.HasCaught()) {
        String::Utf8Value trace(tryCatch.StackTrace());
        WLOG("Error occurred whilst calling NodeJSFunction: %s", *trace ? *trace : "(no trace)");
      }
    }
  });
}


@end
