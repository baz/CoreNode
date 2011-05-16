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


@implementation NodeJSFunction


- (void)dealloc {
  function_.Dispose();
  function_.Clear();
  [super dealloc];
}

- (void)setV8Function:(v8::Local<v8::Function>)function {
  function_ = Persistent<Object>::New(function->ToObject());
}

- (void)invokeWithArguments:(id)argument, ... {
  static const int argcmax = 16;
  Local<Value> *argv = new Local<Value>[argcmax];
  int argc = 0;
  if (argument) {
    va_list valist;
    va_start(valist, argument);
    for (id arg = argument; arg != nil; arg = va_arg(valist, id)) {
      argv[argc++] = [arg v8Value];
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
    // Must be called since this takes care of releasing some resources
    returnCallback(nil, nil, nil);
  });
}


@end
