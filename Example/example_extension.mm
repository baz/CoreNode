//
//  example_extension.mm
//  Core Node Example
//
//  Created by Basil Shkara on 5/12/11.
//  Copyright 2011 Neat.io. All rights reserved.
//

#import <CoreNode/CoreNode.h>

using namespace v8;
using namespace node;


static v8::Handle<Value> SampleMethod(const Arguments& args) {
  NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"test value", @"test key", nil];
  return [CoreNode v8ValueForObject:dictionary];
}

static v8::Handle<Value> PerformNotification(const Arguments& args) {
  dispatch_async(dispatch_get_main_queue(), ^{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"NodeRuntimeNotification" object:nil];
  });
  return Undefined();
}

void example_extension_init(v8::Handle<v8::Object> target) {
  HandleScope scope;

  NODE_SET_METHOD(target, "sampleMethod", SampleMethod);
  NODE_SET_METHOD(target, "performNotification", PerformNotification);
}
