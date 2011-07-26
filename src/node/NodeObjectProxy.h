// Copyright (c) 2010-2011, Rasmus Andersson. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

#import "core_node.h"
#include <map>

#define KN_OBJC_CLASS_ADDITIONS_BEGIN(name) \
  @interface name##_node_ : NSObject {} @end @implementation name##_node_

// Dump a message to stderr
#define KN_DLOG(tmpl, ...)\
  do {\
    fprintf(stderr, "D [node-kod %s:%d] " tmpl "\n", \
            __FILENAME__, __LINE__, ##__VA_ARGS__);\
    fflush(stderr);\
  } while (0)


class NodeObjectProxy : public node::EventEmitter {
 public:
  static v8::Persistent<v8::FunctionTemplate> Initialize(
      v8::Handle<v8::Object> target,
      v8::Handle<v8::String> className,
      const char *srcObjCClassName=NULL);
  static id RepresentedObjectForObjectProxy(v8::Local<v8::Value> objectProxy);

  NodeObjectProxy(id representedObject);
  virtual ~NodeObjectProxy();

  static v8::Handle<v8::Value> New(const v8::Arguments& args);
  static v8::Local<v8::Object> New(v8::Handle<v8::FunctionTemplate> constructor,
                                   id representedObject);
  static v8::Local<v8::Object> New(id representedObject);

  id representedObject_;

 protected:

  typedef std::map<void*, v8::Persistent<v8::FunctionTemplate> >
      PtrToFunctionTemplateMap;
  static PtrToFunctionTemplateMap constructorMap_;
};
