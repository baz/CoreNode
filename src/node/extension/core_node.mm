// Copyright (c) 2010-2011, Rasmus Andersson. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

#import "core_node.h"
#import "common.h"
#import "node_interface.h"
#import "node_ns_additions.h"
#import "NodeThread.h"

NSString *const NodeDidFinishLaunchingNotification = @"NodeDidFinishLaunchingNotification";
BOOL CoreNodeActive = NO;

using namespace v8;
using namespace node;


static v8::Handle<Value> HandleUncaughtException(const Arguments& args) {
  HandleScope scope;
  id err = nil;
  if (args.Length()) {
    if (args[0]->IsObject()) {
      // Don't include arguments (just gets messy when converted to objc)
      args[0]->ToObject()->Delete(String::New("arguments"));
    }
    err = [NSObject fromV8Value:args[0]];
  }
  [NodeThread handleUncaughtException:err];
  return Undefined();
}

// Register a module so that it can be targeted when emitting events or calling functions
static v8::Handle<Value> RegisterObject(const Arguments& args) {
  HandleScope scope;

  if (args.Length() > 1) {
    Local<Value> objectName = args[0];
    Local<Value> moduleValue = args[1];
    if (!moduleValue->IsObject()) return Undefined();

    Persistent<Object> module = Persistent<Object>::New(moduleValue->ToObject());
    String::Utf8Value utf8pch(objectName->ToString());
    registerNodeObject(*utf8pch, module);
  }
  return Undefined();
}

static v8::Handle<Value> UnregisterObjectName(const Arguments& args) {
  if (args.Length()) {
    Local<Value> objectName = args[0];
    String::Utf8Value utf8pch(objectName->ToString());
    unregisterNodeObject(*utf8pch);
  }
  return Undefined();
}

static v8::Handle<Value> NotifyNodeActive(const Arguments& args) {
  dispatch_async(dispatch_get_main_queue(), ^{
    [[NSNotificationCenter defaultCenter] postNotificationName:NodeDidFinishLaunchingNotification object:nil];
  });
  CoreNodeActive = YES;
  return Undefined();
}

void core_node_init(v8::Handle<v8::Object> target) {
  HandleScope scope;

  NSString *version = [onconf_bundle() objectForInfoDictionaryKey:@"CFBundleVersion"];
  target->Set(String::NewSymbol("version"), String::New([version UTF8String]));
  target->Set(String::NewSymbol("binding"), Object::New());

  // Functions
  NODE_SET_METHOD(target, "handleUncaughtException", HandleUncaughtException);
  NODE_SET_METHOD(target, "registerObject", RegisterObject);
  NODE_SET_METHOD(target, "unregisterObjectName", UnregisterObjectName);
  NODE_SET_METHOD(target, "_notifyNodeActive", NotifyNodeActive);
}
