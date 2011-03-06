// Copyright (c) 2010-2011, Rasmus Andersson. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

#import "node_kod.h"
#import "kod_node_interface.h"
#import "knode_ns_additions.h"

#define K_VERSION_STR "1.0"

#import "KObjectProxy.h"

#import "KNodeThread.h"

using namespace v8;
using namespace node;
using namespace kod;

static v8::Handle<Value> GetAllDocuments(const Arguments& args) {
  HandleScope scope;
  NSArray *documents = [NSArray arrayWithObjects:@"MOFO ALL DOCUMENTS", @"Another string", @"Yup it works", nil];
  Local<Value> v = [documents v8Value];
  return scope.Close(v);
}


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
  [KNodeThread handleUncaughtException:err];
  return Undefined();
}


void node_kod_init(v8::Handle<v8::Object> target) {
  HandleScope scope;

  // Constants
  target->Set(String::NewSymbol("version"), String::New(K_VERSION_STR));
  target->Set(String::NewSymbol("exposedFunctions"), Object::New());

  // Functions
  NODE_SET_METHOD(target, "getAllDocuments", GetAllDocuments);
  NODE_SET_METHOD(target, "handleUncaughtException", HandleUncaughtException);

  // Generalized (proxy object) prototypes
//  KObjectProxy::Initialize(target, String::NewSymbol("KSplitView"));
//  KObjectProxy::Initialize(target, String::NewSymbol("KBrowserWindowController"));
//  KObjectProxy::Initialize(target, String::NewSymbol("KDocument"));
//  KObjectProxy::Initialize(target, String::NewSymbol("KScrollView"));
//  KObjectProxy::Initialize(target, String::NewSymbol("KClipView"));
//  KObjectProxy::Initialize(target, String::NewSymbol("KTextView"));
//  KObjectProxy::Initialize(target, String::NewSymbol("KWordDictionary"));

  // init Kod-Node interface
  KNodeInitNode(target);
	
  KObjectProxy::Initialize(target, String::NewSymbol("HelloNode"));

}
