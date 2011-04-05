#import <Foundation/Foundation.h>
#import <objc/runtime.h>

typedef enum {
  KObjCPropUnsupported = 1,
  KObjCPropReadable = 2,
  KObjCPropWritable = 4,
  KObjCPropReturnsPointer = 8,  // returns a pointer
  KObjCPropRetain = 16,         // setter retains value
  KObjCPropCopy = 32,           // setter copies value
  KObjCPropNonAtomic = 64,      // non-atomic
  KObjCPropDynamic = 128,       // @dynamic
  KObjCPropWeak = 256,          // __weak
  KObjCPropGC = 512,            // eligible for garbage collection.
} KObjCPropFlags;

#ifdef __cplusplus
extern "C" {
#endif

KObjCPropFlags k_objc_propattrs(objc_property_t prop,
                                char *returnType,
                                NSString **getterName,
                                NSString **setterName,
                                NSString **className);

#ifdef __cplusplus
}  // extern "C"
#endif
