//
//	NodeJSFunction.h
//	ObjectiveNode
//
//	Created by Basil Shkara on 13/05/11.
//	Copyright 2011 Neat.io Pty Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef __cplusplus
#include <v8.h>
#include <map>
using namespace v8;
#endif


@interface NodeJSFunction : NSObject {
	@private
#ifdef __cplusplus
		v8::Persistent<v8::Function> function_;
		std::map<id, Persistent<Value> > valueCache_;
#endif
}

#ifdef __cplusplus
- (void)setV8Function:(v8::Local<v8::Function>)function;
#endif

- (void)invokeWithArguments:(id)argument, ... NS_REQUIRES_NIL_TERMINATION;


@end
