// Copyright (c) 2010-2011, Rasmus Andersson. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

#import "objective_node.h"
#import "common.h"
#import "node_interface.h"
#import "node_ns_additions.h"
#import "NodeObjectProxy.h"
#import "NodeThread.h"

using namespace v8;
using namespace node;
using namespace kod;


static v8::Handle<Value> HandleUncaughtException(const Arguments& args) {
  HandleScope scope;
  id err = nil;
  if (args.Length() > 0) {
    if (args[0]->IsObject()) {
      // don't include arguments (just gets messy when converted to objc)
      args[0]->ToObject()->Delete(String::New("arguments"));
    }
    err = [NSObject fromV8Value:args[0]];
  }
  [NodeThread handleUncaughtException:err];
  return Undefined();
}

// Register a module so that it can be targeted when emitting events or calling functions
static v8::Handle<Value> RegisterModule(const Arguments& args) {
  HandleScope scope;

  if (args.Length() > 1) {
    Local<Value> moduleName = args[0];
    Local<Value> moduleValue = args[1];
    if (!moduleValue->IsObject()) return Undefined();

    Persistent<Object> module = Persistent<Object>::New(moduleValue->ToObject());
    String::Utf8Value utf8pch(moduleName->ToString());
    char *key = *utf8pch;
    gModulesMap[std::string(key)] = module;
  }
  return Undefined();
}

static v8::Handle<Value> UnregisterModuleName(const Arguments& args) {
  // TODO
  return Undefined();
}

void objective_node_init(v8::Handle<v8::Object> target) {
  HandleScope scope;

  // Constants
  NSString *version = [onconf_bundle() objectForInfoDictionaryKey:@"CFBundleVersion"];
  target->Set(String::NewSymbol("version"), String::New([version UTF8String]));
  target->Set(String::NewSymbol("exposedFunctions"), Object::New());

  // Functions
  NODE_SET_METHOD(target, "handleUncaughtException", HandleUncaughtException);
  NODE_SET_METHOD(target, "registerModule", RegisterModule);
  NODE_SET_METHOD(target, "unregisterModuleName", UnregisterModuleName);

  // init Node interface
  KNodeInitNode(target);
}
// vim: expandtab:ts=2:sw=2
