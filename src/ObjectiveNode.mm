//
//  ObjectiveNode.m
//  ObjectiveNode
//
//  Created by Basil Shkara on 6/03/11.
//  Copyright 2011 Neat IO Pty Ltd. All rights reserved.
//

#import "ObjectiveNode.h"
#import "node_interface.h"
#import "objective_node.h"
#import <v8.h>


@implementation ObjectiveNode


+ (NodeThread *)newNodeThreadForBootstrapPath:(NSString *)bootstrapPath nodePath:(NSString *)nodePath {
	NodeThread *nodeThread = [[NodeThread alloc] initWithBootstrapPath:bootstrapPath nodePath:nodePath];
	return nodeThread;
}

+ (void)emitEvent:(NSString *)eventName onObjectName:(NSString *)objectName arguments:(id)argument, ... {
	static const int argcmax = 16;
	id argv[argcmax];
	int argc = 0;
	if (argument) {
		va_list valist;
		va_start(valist, argument);
		id arg;
		while ((arg = va_arg(valist, id)) && argc < argcmax) {
			argv[argc++] = arg;
		}
		va_end(valist);
	}

	nodeEmitEventv([eventName UTF8String], [objectName UTF8String], argc, argv);
}

+ (void)invokeFunction:(NSString *)functionName onObjectName:(NSString *)objectName arguments:(NSArray *)arguments callback:(NodeCallbackBlock)callbackBlock {
	nodeInvokeFunction([functionName UTF8String], [objectName UTF8String], arguments, callbackBlock);
}

+ (void)injectNodeModule:(moduleInit)moduleInitializer name:(NSString *)name {
	injectNodeModule(moduleInitializer, [name UTF8String], false);
}

+ (BOOL)isNodeActive {
	return ObjectiveNodeActive;
}


@end
