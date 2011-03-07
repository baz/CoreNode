// Copyright (c) 2010-2011, Rasmus Andersson. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

#import "common.h"
#import "NodeThread.h"
#import "objective_node.h"
#import "node_interface.h"

#import <node.h>
#import <node_events.h>

using namespace v8;

static ev_prepare gPrepareNodeWatcher;

static void _KPrepareNode(EV_P_ ev_prepare *watcher, int revents) {
  HandleScope scope;
  kassert(watcher == &gPrepareNodeWatcher);
  kassert(revents == EV_PREPARE);
  //fprintf(stderr, "_KPrepareTick\n"); fflush(stderr);

  // Create global _objective_node module
  Local<FunctionTemplate> kod_template = FunctionTemplate::New();
  node::EventEmitter::Initialize(kod_template);
  gKodNodeModule = Persistent<Object>::New(kod_template->GetFunction()->NewInstance());
  objective_node_init(gKodNodeModule);
  Local<Object> global = v8::Context::GetCurrent()->Global();
  global->Set(String::New("_objective_node"), gKodNodeModule);

  ev_prepare_stop(&gPrepareNodeWatcher);
}


@interface NodeThread()
  @property (nonatomic, copy) NSString *bootstrapPath;
@end

@implementation NodeThread

@synthesize bootstrapPath = bootstrapPath_;


- (void)dealloc {
  [self setBootstrapPath:nil];
  [super dealloc];
}

- (id)initWithBootstrapPath:(NSString *)bootstrapPath {
  self = [super init];
  if (self) {
    self.bootstrapPath = bootstrapPath;
  }

  return self;
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
  NSString *extensionPath = [[onconf_bundle() resourcePath] stringByAppendingPathComponent:@"objective_node"];
  const char *NODE_PATH_pch = getenv("NODE_PATH");
  NSString *NODE_PATH;
  if (NODE_PATH_pch) {
    NODE_PATH = [NSString stringWithFormat:@"%@:%s",extensionPath, NODE_PATH_pch];
  } else {
    NODE_PATH = extensionPath;
  }
  setenv("NODE_PATH", [NODE_PATH UTF8String], 1);

  // Make sure HOME is correct and set
  setenv("HOME", [NSHomeDirectory() UTF8String], 1);

  // register our initializer
  ev_prepare_init(&gPrepareNodeWatcher, _KPrepareNode);
  // set max priority so _KPrepareNode gets called before specified bootstrap file is executed
  ev_set_priority(&gPrepareNodeWatcher, EV_MAXPRI);
  
  while (![self isCancelled]) {

    ev_prepare_start(EV_DEFAULT_UC_ &gPrepareNodeWatcher);
    // Note: We do NOT ev_unref here since we want to keep node alive for as long
    // as we are not canceled.

    // start
    DLOG("[node] starting in %@", self);
    int exitStatus = node::Start(argc, (char**)argv);
    DLOG("[node] exited with status %d in %@", exitStatus, self);

    if (![self isCancelled]) {
      WLOG("forcing program termination due to Node.js unexpectedly exiting");
      [self cancel];
    }
  }

  // clean up
  if (!gKodNodeModule.IsEmpty()) {
    gKodNodeModule.Clear();
    // Note(rsms): Calling gKodNodeModule.Dispose() here seems to bug out on
    // program termination
  }

  [NSApp terminate:nil];
  [pool drain];
}


- (void)cancel {
  // break all currently active ev_run's
  ev_break(EV_DEFAULT_UC_ EVBREAK_ALL);
  
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
}


@end
// vim: expandtab:ts=2:sw=2
