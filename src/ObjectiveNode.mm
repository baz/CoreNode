//
//  ObjectiveNode.m
//  ObjectiveNode
//
//  Created by Basil Shkara on 6/03/11.
//  Copyright 2011 Neat IO Pty Ltd. All rights reserved.
//

#import "ObjectiveNode.h"
#import "NodeThread.h"
#import "node_interface.h"


@implementation ObjectiveNode


+ (NSThread *)newNodeThreadForBootstrapPath:(NSString *)bootstrapPath {
	NodeThread *nodeThread = [[NodeThread alloc] initWithBootstrapPath:bootstrapPath];
	return nodeThread;
}

+ (void)emitEvent:(NSString *)eventName module:(NSString *)moduleName arguments:(id)argument, ... {
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

	nodeEmitEventv([eventName UTF8String], [moduleName UTF8String], argc, argv);
}

+ (void)invokeFunction:(NSString *)functionName module:(NSString *)moduleName arguments:(NSArray *)arguments callback:(NodeCallbackBlock)callbackBlock {
	nodeInvokeFunction([functionName UTF8String], [moduleName UTF8String], arguments, callbackBlock);
}


@end
