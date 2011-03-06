#import "kconf.h"
//#import "HEventEmitter.h"

NSString * const KConfValueDidChangeNotification =
    @"KConfValueDidChangeNotification";

static inline NSURL *_relurl(NSURL *baseurl, NSString *relpath) {
  return relpath ? [baseurl URLByAppendingPathComponent:relpath] : baseurl;
}


NSURL* kconf_res_url(NSString* relpath) {
  return _relurl([kconf_bundle() resourceURL], relpath);
}


NSURL* kconf_support_url(NSString* relpath) {
  return _relurl([kconf_bundle() sharedSupportURL], relpath);
}


NSURL* kconf_url(NSString* key, NSURL* def) {
  NSString *v = [kconf_defaults() stringForKey:key];
  if (!v) {
    return def;
  } else if ([v rangeOfString:@":"].location == NSNotFound) {
    if (![v hasPrefix:@"/"])
      v = [v stringByStandardizingPath];
    return [NSURL fileURLWithPath:v];
  } else {
    return [NSURL URLWithString:v];
  }
}

