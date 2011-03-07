//
//  ObjectiveNode.m
//  ObjectiveNode
//
//  Created by Basil Shkara on 6/03/11.
//  Copyright 2011 Neat IO Pty Ltd. All rights reserved.
//

#import "ObjectiveNode.h"
#import "NodeThread.h"


@implementation ObjectiveNode


+ (NSThread *)newNodeThreadForBootstrapPath:(NSString *)bootstrapPath {
	NodeThread *nodeThread = [[NodeThread alloc] initWithBootstrapPath:bootstrapPath];
	return nodeThread;
}


@end
