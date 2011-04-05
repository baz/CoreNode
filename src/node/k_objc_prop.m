#import "k_objc_prop.h"

KObjCPropFlags k_objc_propattrs(objc_property_t prop,
                                char *returnType,
                                NSString **getterName,
                                NSString **setterName,
                                NSString **className) {
  KObjCPropFlags flags = 0;
  if (returnType) *returnType = 0;
  if (getterName) *getterName = NULL;
  if (setterName) *setterName = NULL;
  if (className) *className = NULL;
  const char *propattrs = property_getAttributes(prop);
  if (!propattrs || propattrs[0] != 'T') return 0;
  size_t propattrslen = strlen(propattrs);
  char section = 0;
  for (int i=0; i<propattrslen; ++i) {
    char c = propattrs[i];
    if (c == ',') {
      section = 0;
    } else if (section == 0) {
      section = c;
      switch (section) {
        case 'R': flags &= ~KObjCPropWritable; break;
        case '&': flags |= KObjCPropRetain; break;
        case 'C': flags |= KObjCPropCopy; break;
        case 'N': flags |= KObjCPropNonAtomic; break;
        case 'D': flags |= KObjCPropDynamic; break;
        case 'W': flags |= KObjCPropWeak; break;
        case 'P': flags |= KObjCPropGC; break;
      }
    } else if (section == 'T') {
      switch (c) {
        case '^':
          flags |= KObjCPropReturnsPointer; break;
        case '(': // union
        case '{': // struct
          // unsupported
          return KObjCPropUnsupported;
        case '@': // object
          {
            // skip over class name
            const char *start = propattrs+i+1;
            const char *end = start;
            while ( (*end != ',') && end && ++end );
            long length = end-start;
            if (className) {
              *className = [[NSString alloc] initWithBytes:start+1
                                                    length:length-2
                                                  encoding:NSUTF8StringEncoding];
              [*className autorelease];
            }
            i += length;
          }
        default:
          if (returnType)
            *returnType = c;
          break;
      }
      flags |= KObjCPropReadable;
      flags |= KObjCPropWritable;
    } else if (section == 'G') {
      // getter
      if (getterName) {
        const char *start = propattrs+i+1;
        const char *end = start;
        while ( (*end != ',') && end && ++end );
        *getterName = [[NSString alloc] initWithBytes:start
                                               length:end-start
                                             encoding:NSUTF8StringEncoding];
        [*getterName autorelease];
      }
    } else if (section == 'S') {
      // setter
      if (setterName) {
        const char *start = propattrs+i+1;
        const char *end = start;
        while ( (*end != ',') && (*end != ':') && end && ++end );
        *setterName = [[NSString alloc] initWithBytes:start
                                               length:end-start
                                             encoding:NSUTF8StringEncoding];
        [*setterName autorelease];
      }
    } else {
      break;
    }
  }
  if (getterName && !*getterName) {
    *getterName = [NSString stringWithUTF8String:property_getName(prop)];
  }
  if (setterName && !*setterName) {
    // construct setter name from |name|
    const char *name = property_getName(prop);
    *setterName = [NSString stringWithFormat:@"set%c%s:",
                   (char)toupper(name[0]), name+1];
  }

  return flags;
}
