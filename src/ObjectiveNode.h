//
//  ObjectiveNode.h
//  ObjectiveNode
//
//  Created by Basil Shkara on 6/03/11.
//  Copyright 2011 Neat IO Pty Ltd. All rights reserved.
//

#import "NodeThread.h"
#import "NodeJSFunction.h"

typedef void (^NodeCallbackBlock)(NSError *error, NSArray *arguments);
extern NSString *const NodeDidFinishLaunchingNotification;

#ifdef __cplusplus
#import <v8.h>
typedef void (*moduleInit)(v8::Handle<v8::Object> target);
#endif


@interface ObjectiveNode : NSObject {
}


+ (NodeThread *)newNodeThreadForBootstrapPath:(NSString *)bootstrapPath nodePath:(NSString *)nodePath;

+ (void)emitEvent:(NSString *)eventName onObjectName:(NSString *)objectName arguments:(id)argument, ... NS_REQUIRES_NIL_TERMINATION;

+ (void)invokeFunction:(NSString *)functionName onObjectName:(NSString *)objectName arguments:(NSArray *)arguments callback:(NodeCallbackBlock)callbackBlock;

+ (id)invokeFunctionSync:(NSString *)functionName onObjectName:(NSString *)objectName arguments:(NSArray *)arguments;

+ (void)enableObjectProxyForClassName:(NSString *)className;

#ifdef __cplusplus
+ (void)injectNodeModule:(moduleInit)moduleInitializer name:(NSString *)name;

+ (id)representedObjectForObjectProxy:(v8::Local<v8::Value>)objectProxy;

+ (v8::Local<v8::Value>)v8ValueForObject:(id)object;

+ (id)objectFromV8Value:(v8::Local<v8::Value>)value;
#endif

+ (BOOL)isNodeActive;


@end
