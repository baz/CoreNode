//
//  ObjectiveNode.h
//  ObjectiveNode
//
//  Created by Basil Shkara on 6/03/11.
//  Copyright 2011 Neat IO Pty Ltd. All rights reserved.
//


@interface ObjectiveNode : NSObject {
}


+ (NSThread *)newNodeThreadForBootstrapPath:(NSString *)bootstrapPath;

+ (void)emitEvent:(NSString *)eventName module:(NSString *)moduleName arguments:(id)argument, ...;

+ (void)callFunction:(NSString *)functionName module:(NSString *)moduleName arguments:(id)argument, ...;


@end
