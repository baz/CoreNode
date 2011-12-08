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
	// Receiving and displaying strings from Node land
	[CoreNode invokeFunction:@"firstMethod" onObjectName:@"exampleModule" arguments:nil callback:^(NSError *error, NSArray *arguments) {
		NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:[arguments componentsJoinedByString:@" "]];
		[self.textView.textStorage appendAttributedString:attributedString];
	}];
}

- (IBAction)didClickSecondButton:(id)sender {
	// Invoking the returned JS closure constructed in Node land
	NSArray *arguments = [NSArray arrayWithObject:@"test argument"];
	[CoreNode invokeFunction:@"secondMethod" onObjectName:@"exampleModule" arguments:arguments callback:^(NSError *error, NSArray *arguments) {
		NodeJSFunction *function = [arguments lastObject];
		[function invokeWithArguments:@"String from Objective-C", nil];
	}];
}

- (IBAction)didClickThirdButton:(id)sender {
	// Passing a proxy object (this object) to a Node function
	NSArray *arguments = [NSArray arrayWithObject:self];
	[CoreNode invokeFunction:@"thirdMethod" onObjectName:@"exampleModule" arguments:arguments callback:nil];
}

- (void)callMe {
	NSLog(@"Inside Objective-C land in %@", NSStringFromSelector(_cmd));
}

- (void)callMe:(NSString *)firstString secondString:(NSString *)secondString {
	NSLog(@"Inside Objective-C land in %@ with strings: '%@' and '%@'", NSStringFromSelector(_cmd), firstString, secondString);
}


@end
