//
//  ObjectiveNode.h
//  ObjectiveNode
//
//  Created by Basil Shkara on 6/03/11.
//  Copyright 2011 Neat IO Pty Ltd. All rights reserved.
//

typedef void (^NodeCallbackBlock)(NSError *error, NSArray *arguments);


@interface ObjectiveNode : NSObject {
}


+ (NSThread *)newNodeThreadForBootstrapPath:(NSString *)bootstrapPath;

+ (void)emitEvent:(NSString *)eventName onObjectName:(NSString *)objectName arguments:(id)argument, ...;

+ (void)invokeFunction:(NSString *)functionName onObjectName:(NSString *)objectName arguments:(NSArray *)arguments callback:(NodeCallbackBlock)callbackBlock;

@end
