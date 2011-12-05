//
//  MainViewController.h
//  CoreNode Example
//
//  Created by Basil Shkara on 5/12/11.
//  Copyright (c) 2011 Neat.io. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MainViewController : NSViewController

@property (nonatomic, strong) IBOutlet NSTextView *textView;

- (IBAction)didClickFirstButton:(id)sender;
- (IBAction)didClickSecondButton:(id)sender;

@end
