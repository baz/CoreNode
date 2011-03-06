// Copyright (c) 2010-2011, Rasmus Andersson. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

#ifndef KOD_EXTERNAL_UTF16_STRING_H_
#define KOD_EXTERNAL_UTF16_STRING_H_
#ifdef __cplusplus

#import <v8.h>
#include <tr1/memory>

namespace kod {

class ExternalUTF16String;
typedef std::tr1::shared_ptr<ExternalUTF16String> ExternalUTF16StringPtr;

/*!
 * Wraps a buffer of UTF-16 characters and can be passed to a v8::String which
 * will then manage the life-cycle of the data (GC-ing as needed).
 *
 * Note: This is safe to use in non-v8 contexts since it only conforms to an
 * interface dictated by v8. This never touches v8-land.
 */
class ExternalUTF16String : public v8::String::ExternalStringResource {
 public:
  // Create an instance which refers to |data| of |length|
  ExternalUTF16String(uint16_t *data, size_t length)
      : data_(data)
      , length_(length) {
  }

#ifdef __OBJC__
  // Creates an instance with a copy of |src|
  ExternalUTF16String(NSString *src) {
    length_ = [src length];
    data_ = new uint16_t[length_];
    [src getCharacters:data_ range:NSMakeRange(0, length_)];
  }
#endif  // __OBJC__

  virtual ~ExternalUTF16String() {
    clear();
  }

  // The string data from the underlying buffer
  void clear(bool freeData=true) {
    if (data_ && freeData) delete data_;
    data_ = NULL;
    length_ = 0;
  }

  // The string data from the underlying buffer
  virtual const uint16_t* data() const { return data_; }

  // Number of characters.
  virtual size_t length() const { return length_; }

#ifdef __OBJC__
  // returns a weak NSString which only holds a reference to our data
  NSString *weakNSString(BOOL freeWhenDone=NO) {
    NSString *s = [[NSString alloc] initWithCharactersNoCopy:data_
                                                      length:length_
                                                freeWhenDone:freeWhenDone];
    return [s autorelease];
  }

  // returns a copy of data
  NSString *toNSString() {
    return [[[NSString alloc] initWithCharacters:data_
                                          length:length_] autorelease];
  }
#endif  // __OBJC__

 protected:
  uint16_t *data_;
  size_t length_;
};


};  // namespace kod

#endif  // __cplusplus
#endif  // KOD_EXTERNAL_UTF16_STRING_H_
