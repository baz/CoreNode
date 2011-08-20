// Copyright (c) 2010-2011, Rasmus Andersson. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.


typedef void(^NodeModuleInitializeBlock)(void);
extern NSString *const NodeThreadDidFinishExiting;
extern NSString *const NodeThreadDidCatchUnhandledException;


@interface NodeThread : NSThread {
  @private
    NSString *bootstrapPath_;
    NSString *nodePath_;
}

- (id)initWithBootstrapPath:(NSString *)bootstrapPath nodePath:(NSString *)nodePath;
+ (void)setModuleInitializeBlock:(NodeModuleInitializeBlock)moduleInitializer;
+ (void)handleUncaughtException:(id)err;
- (void)setEnvironment:(NSDictionary *)environment;

@end
