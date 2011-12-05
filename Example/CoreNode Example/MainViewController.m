//
//  MainViewController.m
//  CoreNode Example
//
//  Created by Basil Shkara on 5/12/11.
//  Copyright (c) 2011 Neat.io. All rights reserved.
//

#import "MainViewController.h"
#import <CoreNode/CoreNode.h>

@implementation MainViewController

@synthesize textView = textView_;


- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)awakeFromNib {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveNodeNotification) name:@"NodeRuntimeNotification" object:nil];
}

- (void)didReceiveNodeNotification {
	NSLog(@"Node notification received in Objective-C land.");
}

- (IBAction)didClickFirstButton:(id)sender {
	[CoreNode invokeFunction:@"firstMethod" onObjectName:@"exampleModule" arguments:nil callback:^(NSError *error, NSArray *arguments) {
		NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:[arguments componentsJoinedByString:@" "]];
		[self.textView.textStorage appendAttributedString:attributedString];
	}];
}

- (IBAction)didClickSecondButton:(id)sender {
	NSArray *arguments = [NSArray arrayWithObject:@"test argument"];
	[CoreNode invokeFunction:@"secondMethod" onObjectName:@"exampleModule" arguments:arguments callback:^(NSError *error, NSArray *arguments) {
		NodeJSFunction *function = [arguments lastObject];
		[function invokeWithArguments:@"String from Objective-C", nil];
	}];
}


@end
