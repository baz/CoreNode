// Copyright (c) 2010-2011, Rasmus Andersson. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

#import <node.h>
#import <node_events.h>
#ifdef __OBJC__
#import <Cocoa/Cocoa.h>
#endif

// Creates a new UTF-8 C string from a Value.
// Note: if you only need to access the string (i.e. not make a copy of it) you
// can use String::Utf8Value:
//   String::Utf8Value foo(value);
//   const char *temp = *foo;
static inline char* KNToCString(v8::Handle<v8::Value> value) {
  v8::Local<v8::String> str = value->ToString();
  char *p = new char[str->Utf8Length()];
  str->WriteUtf8(p);
  return p;
}

// Initialize this module
void objective_node_init(v8::Handle<v8::Object> target);
