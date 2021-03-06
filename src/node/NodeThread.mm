// Copyright (c) 2010-2011, Rasmus Andersson. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

#import "common.h"
#import "NodeThread.h"
#import "core_node.h"
#import "node_interface.h"
#import <node.h>
#import <node_events.h>

using namespace v8;

static ev_prepare gPrepareNodeWatcher;
static NodeModuleInitializeBlock ModuleInitializer;
NSString *const NodeThreadDidFinishExiting = @"NodeThreadDidFinishExiting";
NSString *const NodeThreadDidCatchUnhandledException = @"NodeThreadDidCatchUnhandledException";


static void _KPrepareNode(EV_P_ ev_prepare *watcher, int revents) {
  HandleScope scope;
  kassert(watcher == &gPrepareNodeWatcher);
  kassert(revents == EV_PREPARE);

  // Create global _core_node module
  injectNodeModule(&core_node_init, "_core_node", true);

  // Init Node interface
  NodeInitNode();

  // Allow others to initialize modules
  if (ModuleInitializer) {
    ModuleInitializer();
    [ModuleInitializer release];
  }

  ev_prepare_stop(&gPrepareNodeWatcher);
}


@interface NodeThread()
  @property (nonatomic, copy) NSString *bootstrapPath;
  @property (nonatomic, copy) NSString *nodePath;
@end

@implementation NodeThread

@synthesize bootstrapPath = bootstrapPath_;
@synthesize nodePath = nodePath_;


- (void)dealloc {
  [self setBootstrapPath:nil];
  [self setNodePath:nil];
  if (ModuleInitializer) [ModuleInitializer release];
  [super dealloc];
}

- (id)initWithBootstrapPath:(NSString *)bootstrapPath nodePath:(NSString *)nodePath {
  self = [super init];
  if (self) {
    self.bootstrapPath = bootstrapPath;
    self.nodePath = nodePath;
  }

  return self;
}

+ (void)setModuleInitializeBlock:(NodeModuleInitializeBlock)moduleInitializer {
  ModuleInitializer = [moduleInitializer copy];
}

- (void)setEnvironment:(NSDictionary *)environment {
  for (NSString *key in environment) {
    NSString *value = [environment objectForKey:key];
    setenv([key UTF8String], [value UTF8String], 1);
  }
}

- (void)main {
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  // args
  const char *argv[] = {NULL,"","",NULL};
  argv[0] = [[onconf_bundle() executablePath] UTF8String];
  int argc = 2;
  #if !NDEBUG || K_DEBUG_V8_EXPOSE_GC
    argv[1] = "--expose-gc";
    argc++;
    #if K_DEBUG_V8_TRACE_GC
      argv[2] = "--trace-gc";
      argc++;
    #endif
  #endif
  if (self.bootstrapPath) argv[argc-1] = [self.bootstrapPath UTF8String];

  // NODE_PATH
  NSString *extensionPath = [[onconf_bundle() resourcePath] stringByAppendingPathComponent:@"core_node"];
  NSString *nodePath = nil;
  const char *node_path_pch = getenv("NODE_PATH");
  if (self.nodePath) {
    if (node_path_pch) {
      nodePath = [NSString stringWithFormat:@"%@:%@:%s", self.nodePath, extensionPath, node_path_pch];
    } else {
      nodePath = [NSString stringWithFormat:@"%@:%@", self.nodePath, extensionPath];
    }
  } else if (node_path_pch) {
    nodePath = [NSString stringWithFormat:@"%@:%s", extensionPath, node_path_pch];
  }
  setenv("NODE_PATH", [nodePath UTF8String], 1);

  // Make sure HOME is correct and set
  setenv("HOME", [NSHomeDirectory() UTF8String], 1);

  // register our initializer
  ev_prepare_init(&gPrepareNodeWatcher, _KPrepareNode);
  // set max priority so _KPrepareNode gets called before specified bootstrap file is executed
  ev_set_priority(&gPrepareNodeWatcher, EV_MAXPRI);
  
  if (![self isCancelled]) {
    ev_prepare_start(EV_DEFAULT_UC_ &gPrepareNodeWatcher);
    // Note: We do NOT ev_unref here since we want to keep node alive for as long
    // as we are not cancelled.

    // start
    int exitStatus = node::Start(argc, (char**)argv);
    DLOG("[node] exited with status %d in %@", exitStatus, self);
  }

  unregisterAllNodeObjects();

  [pool drain];

  dispatch_async(dispatch_get_main_queue(), ^{
    [[NSNotificationCenter defaultCenter] postNotificationName:NodeThreadDidFinishExiting object:self];
  });
}


- (void)cancel {
  // break all currently active ev_run's
  ev_break(EV_DEFAULT_UC_ EVBREAK_ALL);

  // exit the current event loop
  ev_unref(EV_DEFAULT_UC_);

  [super cancel];
}


+ (void)handleUncaughtException:(id)err {
  // called in the node thead
  id msg = err;
  if ([err isKindOfClass:[NSDictionary class]]) {
    if (!(msg = [err objectForKey:@"stack"]))
      msg = err;
  }
  WLOG("[node] unhandled exception: %@", msg);

  dispatch_async(dispatch_get_main_queue(), ^{
    [[NSNotificationCenter defaultCenter] postNotificationName:NodeThreadDidCatchUnhandledException object:msg];
  });
}


@end
