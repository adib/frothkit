// Copyright (c) 2007-2008 Michael Buckley

// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:

// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

#import <Foundation/Foundation.h>
#import <inttypes.h>
#import <pthread.h>

@interface BTLSocketBuffer : NSObject {
	//! \brief The position of the buffer.
	//!
	//! All reading and writing methods will begin from this position
	int64_t position;
	
	//! \brief The total size of the buffer.
	int64_t size;
	
	//! \brief The buffer's data, represented as an array of bytes.
	char* rawData;
	
	//! brief YES if the most recent read operation succeeded, NO otherwise.
	
	//! \brief An array of pointers to be freed with free() when the buffer is
	//! deallocated.
	void** privateRetainedPointers;
	
	//! \brief The number of pointers to free when the buffer is deallocated.
	int numPrivateRetainedPointers;
	
	pthread_mutex_t bufferMutex;
}

#ifdef KEEP_UNDEFINED
#pragma mark Adding Data
#endif

- (BOOL)allocateSpaceOfSize:(int64_t)theSize;
- (BOOL)addData:(const void*)someData ofSize:(int64_t)theSize;
- (BOOL)addBuffer:(BTLSocketBuffer*)aBuffer;
- (BOOL)addRemainingBuffer:(BTLSocketBuffer*)aBuffer;

#ifdef KEEP_UNDEFINED
#pragma mark Adding Numbers
#endif

- (BOOL)addInt8:(int8_t)anInt;
- (BOOL)addInt16:(int16_t)anInt;
- (BOOL)addInt32:(int32_t)anInt;
- (BOOL)addInt64:(int64_t)anInt;
- (BOOL)addInt:(void*)anInt ofSize:(int64_t)theSize;

- (BOOL)addFloat:(float)aFloat;
- (BOOL)addDouble:(double)aDouble;

#ifdef KEEP_UNDEFINED
#pragma mark Getting Numbers
#endif

- (int8_t)getInt8;
- (int16_t)getInt16;
- (int32_t)getInt32;
- (int64_t)getInt64;
- (void*)getIntOfSize:(int64_t)theSize;

- (float)getFloat;
- (double)getDouble;

#ifdef KEEP_UNDEFINED
#pragma mark Getting Strings
#endif

- (char*)getNullTerminatedString;
- (NSString*)getNullTerminatedNSString;
- (NSString*)getNullTerminatedNSStringWithEncoding:(NSStringEncoding)theEncoding;

- (char*)getStringTerminatedByLinebreak;
- (NSString*)getNSStringTerminatedByLinebreak;
- (NSString*)getNSStringTerminatedByLinebreakWithEncoding:(NSStringEncoding)theEncoding;

- (char*)getStringTerminatedBy:(char*)aTerminal includeTerminal:(BOOL)aBool;
- (NSString*)getNSStringTerminatedBy:(char*)aTerminal includeTerminal:(BOOL)aBool;
- (NSString*)getNSStringTerminatedBy:(char*)aTerminal includeTerminal:(BOOL)aBool encoding:(NSStringEncoding)theEncoding;

- (char*)getStringOfSize:(int64_t)theSize;
- (NSString*)getNSStringOfSize:(int64_t)theSize;
- (NSString*)getNSStringOfSize:(int64_t)theSize encoding:(NSStringEncoding)theEncoding;

#ifdef KEEP_UNDEFINED
#pragma mark Getting Raw Data
#endif

- (const char*)rawData;
- (char*)remainingRawData;

#ifdef KEEP_UNDEFINED
#pragma mark Controlling Position
#endif

- (void)rewind;
- (void)unwind;
- (BOOL)unGet:(int64_t)length;
- (BOOL)skip:(int64_t)length;

- (BOOL)setPosition:(int64_t)newPosition;
- (int64_t)position;

#ifdef KEEP_UNDEFINED
#pragma mark Accessors
#endif

- (BOOL)readSucceeded;
- (int64_t)size;
- (int64_t)remainingSize;

@end

#ifdef KEEP_UNDEFINED
#pragma mark Network Order Functions
#endif

void* htonx(void* v, int length);
void* ntohx(void* v, int length);
void* flip(void* v, int length);
