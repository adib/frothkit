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

#import "BTLSocketBuffer.h"
#import "BTLSocketBuffer+Protected.h"
#import "BTLEndian.h"

#include <netinet/in.h>

//! The BTLSocketBuffer class provides an endian-neutural buffer which stores
//! data as a sequence of bytes in network order.

@interface BTLSocketBuffer (Private)

#ifdef KEEP_UNDEFINED
#pragma mark Getting Strings
#endif

- (char*)privateGetNullTerminatedString;
- (char*)privateGetStringTerminatedByLinebreak;
- (char*)privateGetStringTerminatedBy:(char*)aTerminal includeTerminal:(BOOL)aBool;
- (char*)privateGetStringOfSize:(int64_t)theSize;

#ifdef KEEP_UNDEFINED
#pragma mark Memory Management
#endif

- (BOOL)privateAddRetainedPointers:(void*)aPointer;

@end

pthread_key_t privateReadSucceededKey;

@implementation BTLSocketBuffer

#ifdef KEEP_UNDEFINED
#pragma mark Initializers
#endif

+ (void)initialize
{
	pthread_key_create(&privateReadSucceededKey, free);
}

- (id)init
{
	self = [super init];
	rawData = NULL;
	
	size = 0;
	[self setPosition:0];
	
	[self protectedSetReadSucceeded:NO];
	
	privateRetainedPointers = NULL;
	numPrivateRetainedPointers = 0;
	
	pthread_mutex_init(&bufferMutex, NULL);
	
	return self;
}

#ifdef KEEP_UNDEFINED
#pragma mark Copying
#endif

- (id)copyWithZone:(NSZone*)zone
{
	id ret = [[self class] new];
	if(size > 0 && ![ret addData:rawData ofSize:size]){
		return nil;
	}
	return ret;
}

#ifdef KEEP_UNDEFINED
#pragma mark Adding Data
#endif

//! \brief Ensures that the buffer is large enough to accomodate theSize more
//! bytes without growing the buffer.
//!
//! When the buffer is at capacity and more data is added to it, it grows to
//! accomodate that data, but may not grow larger than that. Thus, adding many
//! pieces of data when the buffer is at capacity will cause it to grow many
//! times. If the size of the combined size of the data about to be added is
//! known ahead of time, calling this method will improve performance.
//!
//! \returns YES if the operation succeeded or there is already enough space, NO
//! if theSize is less than 0 or would cause an overflow or if the operation
//! failed.

- (BOOL)allocateSpaceOfSize:(int64_t)theSize
{
	pthread_mutex_lock(&bufferMutex);
	BOOL ret = YES;
	if(theSize < 0 || INT64_MAX - theSize < position){ // Overflow
		ret = NO;
	}else if(position + theSize > size){
		void* temp = (char*) realloc(rawData, sizeof(char) * (position + theSize));
		if(temp == NULL){
			ret = NO;
		}else{
			rawData = temp;
			size = position + theSize;
		}
	}
	
	pthread_mutex_unlock(&bufferMutex);
	return ret;
}

//! \brief Adds data of the specified size to the buffer.

- (BOOL)addData:(const void*)someData ofSize:(int64_t)theSize
{
	pthread_mutex_lock(&bufferMutex);
	BOOL ret = YES;
	if(someData == NULL || theSize <= 0 || INT64_MAX - theSize < position){
		ret = NO;
	}else if(size == 0){
		rawData = (char*) malloc(sizeof(char) * theSize);
		if(rawData == NULL){
			ret = NO;
		}
	}else{
		void* temp = (char*) realloc(rawData, sizeof(char) * (size + theSize));
		if(temp == NULL){
			ret = NO;
		}else{
			rawData = temp;
		}
	}
	
	if(ret == YES){
		memcpy(&(rawData[size]), someData, theSize);
		size = size + theSize;
	}
	
	pthread_mutex_unlock(&bufferMutex);
	return ret;
}

//! \brief Adds the contents of another buffer to the buffer.

- (BOOL)addBuffer:(BTLSocketBuffer*)aBuffer
{
	return [self addData:[aBuffer rawData] ofSize:[aBuffer size]];
}

//! \brief Adds the remaining contents another the buffer to the buffer.

- (BOOL)addRemainingBuffer:(BTLSocketBuffer*)aBuffer
{
	return [self addData:[aBuffer rawData] + [aBuffer position] ofSize:[aBuffer remainingSize]];
}

#ifdef KEEP_UNDEFINED
#pragma mark Adding Numbers
#endif

//! \brief Adds a single character to the buffer.

- (BOOL)addInt8:(int8_t)anInt
{
	return [self addData:&anInt ofSize:1];
}

//! \brief Adds a two-byte integer to the buffer.
//!
//! The integer will be stored in network order, so retreiving this integer by
//! any other method than getInt16 will return a different value on all but
//! big endian systems.

- (BOOL)addInt16:(int16_t)anInt
{
	anInt = htons(anInt);
	return [self addData:&anInt ofSize:2];
}

//! \brief Adds a four-byte integer to the buffer.
//!
//! The integer will be stored in network order, so retreiving this integer by
//! any other method than getInt32 will return a different value on all but
//! big endian systems.

- (BOOL)addInt32:(int32_t)anInt
{
	anInt = htonl(anInt);
	return [self addData:&anInt ofSize:4];
}

//! \brief Adds a eight-byte integer to the buffer.
//!
//! The integer will be stored in network order, so retreiving this integer by
//! any other method than getInt64 will return a different value on all but
//! big endian systems.

- (BOOL)addInt64:(int64_t)anInt
{
	BOOL ret = YES;
	int* temp = (int*) htonx(&anInt, 8);
	if(temp == NULL){
		ret = NO;
	}else{
		ret = [self addData:temp ofSize:8];
		free(temp);
	}
	
	return ret;
}

//! \brief Adds an integer of the specified size to the buffer.
//!
//! The integer will be stored in network order, so retreiving this integer by
//! any other method than getIntOfSize: will return a different value on all but
//! big endian systems.

- (BOOL)addInt:(void*)anInt ofSize:(int64_t)theSize
{
	BOOL ret = YES;
	if(anInt == NULL || theSize <= 0 || INT64_MAX - theSize < position){
		ret = NO;
	}else{
		void* temp = htonx(anInt, theSize);
		if(temp == NULL){
			ret = NO;
		}else{
			ret = [self addData:temp ofSize:theSize];
			free(temp);
		}
	}
	
	return ret;
}

//! \brief Adds a four-byte float to the buffer.
//!
//! The integer will be stored in network order, so retreiving this integer by
//! any other method than getFloat will return a different value on all but big
//! endian systems.

- (BOOL)addFloat:(float)aFloat
{
	return [self addInt:&aFloat ofSize:4];
}

//! \brief Adds an eight-byte double to the buffer.
//!
//! The integer will be stored in network order, so retreiving this integer by
//! any other method than getDouble will return a different value on all but big
//! endian systems.

- (BOOL)addDouble:(double)aDouble
{
	return [self addInt:&aDouble ofSize:8];
}

#ifdef KEEP_UNDEFINED
#pragma mark Getting Numbers
#endif

//! \returns the next character in the buffer.
//!
//! This method will fail if there are no more bytes in the buffer, in which
//! case readSucceeded will be set to NO, and the position will not be
//! advanced.

- (int8_t)getInt8
{
	pthread_mutex_lock(&bufferMutex);
	uint8_t ret = 0;
	if(position < size){
		++position;
		[self protectedSetReadSucceeded:YES];
		ret = rawData[position - 1];
	}else{
		[self protectedSetReadSucceeded:NO];
	}
	pthread_mutex_unlock(&bufferMutex);
	return ret;
}

//! \returns the next two-byte integer in the buffer.
//!
//! This method will fail if it reaches the end if the buffer prematurely, in
//! which case readSucceeded will be set to NO, and the position will not be
//! advanced.

- (int16_t)getInt16
{
	int16_t ret = 0;
	char* temp = [self privateGetStringOfSize:2];
	if(temp != NULL){
		memcpy(&ret, temp, 2);
		free(temp);
	}
	
	return ntohs(ret);
}

//! \returns the next four-byte integer in the buffer.
//!
//! This method will fail if it reaches the end if the buffer prematurely, in
//! which case readSucceeded will be set to NO, and the position will not be
//! advanced.

- (int32_t)getInt32
{
	int32_t ret = 0;
	char* temp = [self privateGetStringOfSize:4];
	if(temp != NULL){
		memcpy(&ret, temp, 4);
		free(temp);
	}
	
	return ntohl(ret);
}

//! \returns the next eight-byte integer in the buffer.
//!
//! This method will fail if it reaches the end if the buffer prematurely, in
//! which case readSucceeded will be set to NO, and the position will not be
//! advanced.

- (int64_t)getInt64
{
	int64_t ret = 0;
	char* temp = [self privateGetStringOfSize:8];
	if(temp != NULL){
		memcpy(&ret, temp, 8);
		free(temp);
		temp = ntohx(&ret, 8);
		memcpy(&ret, temp, 8);
		free(temp);
	}
	
	return ret;
}

//! \returns the next integer of the specified size in the buffer.
//!
//! This method will fail if it reaches the end if the buffer prematurely, in
//! which case readSucceeded will be set to NO, and the position will not be
//! advanced.

- (void*)getIntOfSize:(int64_t)theSize
{
	pthread_mutex_lock(&bufferMutex);
	char* ret = NULL;
	[self protectedSetReadSucceeded:NO];
	
	if(theSize > 0 && INT64_MAX - theSize >= position){
		ret = (char*) malloc(theSize);
		if(ret != NULL){
			memset(ret, 0, theSize);
			char* temp = [self privateGetStringOfSize:theSize];
	
			if(temp != NULL){
				memcpy(ret, temp, theSize);
				free(temp);
				temp = ntohx(ret, theSize);
				memcpy(ret, temp, theSize);
				free(temp);
				if(![self privateAddRetainedPointers:ret]){
					free(ret);
					ret = NULL;
					[self protectedSetReadSucceeded:NO];
				}
			}else{
				[self protectedSetReadSucceeded:NO];
			}
		}
	}
	
	pthread_mutex_unlock(&bufferMutex);
	return (void*) ret;
}

//! \returns the next four-byte float in the buffer.
//!
//! This method will fail if it reaches the end if the buffer prematurely, in
//! which case readSucceeded will be set to NO, and the position will not be
//! advanced.

- (float)getFloat
{
	pthread_mutex_lock(&bufferMutex);
	float ret = 0.0f;
	
	char* temp = [self privateGetStringOfSize:4];
	if(temp != NULL){
		memcpy(&ret, temp, 4);
		free(temp);
		temp = ntohx(&ret, 4);
		memcpy(&ret, temp, 4);
		free(temp);
	}
	
	pthread_mutex_unlock(&bufferMutex);
	return ret;
}

//! \returns the next eight-byte double in the buffer.
//!
//! This method will fail if it reaches the end if the buffer prematurely, in
//! which case readSucceeded will be set to NO, and the position will not be
//! advanced.

- (double)getDouble
{
	pthread_mutex_lock(&bufferMutex);
	double ret = 0.0;
	
	char* temp = [self privateGetStringOfSize:8];
	if(temp != NULL){
		memcpy(&ret, temp, 8);
		free(temp);
		temp = ntohx(&ret, 8);
		memcpy(&ret, temp, 8);
		free(temp);
	}
	
	pthread_mutex_unlock(&bufferMutex);
	return ret;
}

#ifdef KEEP_UNDEFINED
#pragma mark Getting Strings
#endif

//! \returns a character array containing all characters between the buffer's
//! position and the next NULL character in the buffer, including the NULL
//! character.
//! This method will fail if it reaches the end if the buffer prematurely, in
//! which case readSucceeded will be set to NO, and the position will not be
//! advanced.

- (char*)getNullTerminatedString
{
	pthread_mutex_lock(&bufferMutex);
	char* ret = [self privateGetNullTerminatedString];
	
	if(ret != NULL){
		if(![self privateAddRetainedPointers:ret]){
			free(ret);
			ret = NULL;
			[self protectedSetReadSucceeded:NO];
		}
	}
	
	pthread_mutex_unlock(&bufferMutex);
	return ret;
}

//! \returns an NSString created with the data between the buffer's position and
//! the next NULL character in the buffer, treating the data as a UTF-8 string.
//!
//! This method will fail if it reaches the end if the buffer prematurely, in
//! which case readSucceeded will be set to NO, and the position will not be
//! advanced.

- (NSString*)getNullTerminatedNSString
{
	return [self getNullTerminatedNSStringWithEncoding:NSUTF8StringEncoding];
}

//! \returns an NSString created with the data between the buffer's position and
//! the next NULL character in the buffer, treating the data as the specified
//! encoding.
//!
//! This method will fail if it reaches the end if the buffer prematurely, in
//! which case readSucceeded will be set to NO, and the position will not be
//! advanced.

- (NSString*)getNullTerminatedNSStringWithEncoding:(NSStringEncoding)theEncoding
{
	pthread_mutex_lock(&bufferMutex);
	NSString* ret = nil;
	char* temp = [self privateGetNullTerminatedString];
	
	if(temp != NULL){
		ret = [[NSString alloc] initWithCString:temp encoding:theEncoding];
		free(temp);
	}
	
	pthread_mutex_unlock(&bufferMutex);
	return [ret autorelease];
}

//! \returns a NULL-terminated character array of all the characters between the
//! buffer's current position and the next \r\n, \r or \n linebreak, not
//! including the linebreak.
//!
//! This method will fail if it reaches the end if the buffer prematurely, in
//! which case readSucceeded will be set to NO, and the position will not be
//! advanced.

- (char*)getStringTerminatedByLinebreak
{
	pthread_mutex_lock(&bufferMutex);
	char* ret = [self privateGetStringTerminatedByLinebreak];
	
	if(ret != NULL){
		if(![self privateAddRetainedPointers:ret]){
			free(ret);
			ret = NULL;
			[self protectedSetReadSucceeded:NO];
		}
	}
	
	pthread_mutex_unlock(&bufferMutex);
	return ret;
}

//! \returns an NSString created with the data between the buffer's position and
//! the next \r\n, \r or \n linebreak, not including the linebreak and treating
//! the data as a UTF-8 string.
//!
//! This method will fail if it reaches the end if the buffer prematurely, in
//! which case readSucceeded will be set to NO, and the position will not be
//! advanced.

- (NSString*)getNSStringTerminatedByLinebreak
{
	return [self getNSStringTerminatedByLinebreakWithEncoding:NSUTF8StringEncoding];
}

//! \returns an NSString created with the data between the buffer's position and
//! the next \r\n, \r or \n linebreak, not including the linebreak and treating
//! the data as the specified encoding.
//!
//! This method will fail if it reaches the end if the buffer prematurely, in
//! which case readSucceeded will be set to NO, and the position will not be
//! advanced.

- (NSString*)getNSStringTerminatedByLinebreakWithEncoding:(NSStringEncoding)theEncoding
{
	pthread_mutex_lock(&bufferMutex);
	NSString* ret = nil;
	char* temp = [self privateGetStringTerminatedByLinebreak];
	
	if(temp != NULL){
		ret = [[NSString alloc] initWithCString:temp encoding:theEncoding];
		free(temp);
	}
	
	pthread_mutex_unlock(&bufferMutex);
	return [ret autorelease];
}

//! \returns a NULL-terminated character array of all the characters between the
//! buffer's current position and the next instance of the terminal, including
//! the terminal.
//!
//! The terminal must be a NULL-terminated character array, but the NULL is not
//! considered to be part of the terminal.
//!
//! This method will fail if it reaches the end if the buffer prematurely, in
//! which case readSucceeded will be set to NO, and the position will not be
//! advanced.

- (char*)getStringTerminatedBy:(char*)aTerminal includeTerminal:(BOOL)aBool
{
	pthread_mutex_lock(&bufferMutex);
	char* ret = [self privateGetStringTerminatedBy:aTerminal includeTerminal:aBool];
	
	if(ret != NULL){
		if(![self privateAddRetainedPointers:ret]){
			free(ret);
			ret = NULL;
			[self protectedSetReadSucceeded:NO];
		}
	}
	
	pthread_mutex_unlock(&bufferMutex);
	return ret;
}

//! \returns an NSString created with the data between the buffer's position and
//! the next instance of the terminal, including the terminal and treating the
//! data as a UTF-8 string.
//!
//! The terminal must be a NULL-terminated character array, but the NULL is not
//! considered to be part of the terminal.
//!
//! This method will fail if it reaches the end if the buffer prematurely, in
//! which case readSucceeded will be set to NO, and the position will not be
//! advanced.

- (NSString*)getNSStringTerminatedBy:(char*)aTerminal includeTerminal:(BOOL)aBool
{
	return [self getNSStringTerminatedBy:aTerminal includeTerminal:aBool encoding:NSUTF8StringEncoding];
}

//! \returns an NSString created with the data between the buffer's position and
//! the next instance of the terminal, including the terminal and treating the
//! data as the specified encoding.
//!
//! The terminal must be a NULL-terminated character array, but the NULL is not
//! considered to be part of the terminal.
//!
//! This method will fail if it reaches the end if the buffer prematurely, in
//! which case readSucceeded will be set to NO, and the position will not be
//! advanced.

- (NSString*)getNSStringTerminatedBy:(char*)aTerminal includeTerminal:(BOOL)aBool encoding:(NSStringEncoding)theEncoding
{
	pthread_mutex_lock(&bufferMutex);
	NSString* ret = nil;
	char* temp = [self privateGetStringTerminatedBy:aTerminal includeTerminal:aBool];
	
	if(temp != NULL){
		ret = [[NSString alloc] initWithCString:temp encoding:theEncoding];
		free(temp);
	}
	
	pthread_mutex_unlock(&bufferMutex);
	return [ret autorelease];
}

//! \returns a NULL-terminated character array of the specified size.
//!
//! This method will fail if it reaches the end if the buffer prematurely, in
//! which case readSucceeded will be set to NO, and the position will not be
//! advanced.

- (char*)getStringOfSize:(int64_t)theSize
{
	pthread_mutex_lock(&bufferMutex);
	char* ret = NULL;
	[self protectedSetReadSucceeded:NO];
	if(theSize > 0 && INT64_MAX - theSize >= position){ // Overflow
		ret = [self privateGetStringOfSize:theSize];
		if(ret != NULL){
			if(![self privateAddRetainedPointers:ret]){
				free(ret);
				ret = NULL;
				[self protectedSetReadSucceeded:NO];
			}
		}
	}
	
	pthread_mutex_unlock(&bufferMutex);
	return ret;
}

//! \returns an NSString of the specified size, treating the data as a UTF-8
//! string.
//!
//! This method will fail if it reaches the end if the buffer prematurely, in
//! which case readSucceeded will be set to NO, and the position will not be
//! advanced.

- (NSString*)getNSStringOfSize:(int64_t)theSize
{
	return [self getNSStringOfSize:theSize encoding:NSUTF8StringEncoding];
}

//! \returns an NSString of the specified size, treating the data as the
//! specified encoding.
//!
//! This method will fail if it reaches the end if the buffer prematurely, in
//! which case readSucceeded will be set to NO, and the position will not be
//! advanced.

- (NSString*)getNSStringOfSize:(int64_t)theSize encoding:(NSStringEncoding)theEncoding
{
	pthread_mutex_lock(&bufferMutex);
	NSString* ret = nil;
	[self protectedSetReadSucceeded:NO];
	if(theSize > 0 && INT64_MAX - theSize >= position){ // Overflow
		char* temp = [self privateGetStringOfSize:theSize];
	
		if(temp != NULL){
			ret = [[NSString alloc] initWithCString:temp encoding:theEncoding];
			free(temp);
		}
	}
	
	pthread_mutex_unlock(&bufferMutex);
	return [ret autorelease];
}

#ifdef KEEP_UNDEFINED
#pragma mark Getting Raw Data
#endif

//! \returns a non-modifiable character array representing the buffer's data.

- (const char*)rawData
{
	pthread_mutex_lock(&bufferMutex);
	if(size < 1){
		return NULL;
	}
	
	const char* ret = rawData;
	pthread_mutex_unlock(&bufferMutex);
	return ret;
}

//! returns a modifiable character array representing the remaining data in the
//! buffer.

- (char*)remainingRawData
{
	pthread_mutex_lock(&bufferMutex);
	char* ret = NULL;
	int length = size - position;
	
	if(length > 0){
		ret = (char*) malloc(sizeof(char) * length);
		if(ret != NULL){
			int i;
			for(i = 0; i < length; ++i){
				ret[i] = rawData[position + i];
			}
			if(![self privateAddRetainedPointers:ret]){
				free(ret);
				ret = NULL;
				[self protectedSetReadSucceeded:NO];
			}else{
				[self protectedSetReadSucceeded:YES];
			}
		}else{
			[self protectedSetReadSucceeded:NO];
		}
	}
	
	pthread_mutex_unlock(&bufferMutex);
	return ret;
}

#ifdef KEEP_UNDEFINED
#pragma mark Controlling Position
#endif

//! \brief Sets the buffer's position at the beginning of the buffer.

- (void)rewind
{
	[self setPosition:0];
}

//! \brief Sets the buffer's position at the end of the buffer.

- (void)unwind
{
	[self setPosition:[self size]];
}

//! \brief Moves the buffer's position backwards theSize bytes.
//!
//! If theSize is greater than the buffer's current position, the position will
//! be set to the beginning of the buffer.

- (BOOL)unGet:(int64_t)theSize
{
	BOOL ret = NO;
	if(theSize >= 0){
		ret = [self setPosition: [self position] - theSize];
	}
	
	return ret;
}

//! \brief Moves the buffer's position forwards theSize bytes.
//!
//! If theSize is greater than the buffer's size, the position will be set to
//! the end of the buffer.

- (BOOL)skip:(int64_t)theSize
{
	BOOL ret = NO;
	if(theSize >= 0){
		ret = [self setPosition: [self position] + theSize];
	}
	
	return ret;
}

#ifdef KEEP_UNDEFINED
#pragma mark Testing Equality
#endif

- (BOOL)isEqual:(id)anObject
{
	if(anObject == nil){
		return NO;
	}
	
	if(anObject == self){
		return YES;
	}
	
	BOOL ret = YES;
	
	if([anObject isKindOfClass:[self class]]){
		BTLSocketBuffer* other = anObject;
		pthread_mutex_lock(&bufferMutex);
		
		if([other size] != size){
			ret = NO;
		}else{
			const char* otherData = [other rawData];
		
			int i;
			for(i = 0; i < size; ++i){
				if(otherData[i] != rawData[i]){
				   ret = NO;
				}
			}
		}
		
		pthread_mutex_unlock(&bufferMutex);
	}else{
		ret = NO;
	}
	
	return ret;
}

#ifndef NSINTEGER_DEFINED
#if __LP64__ || NS_BUILD_32_LIKE_64
typedef long NSInteger;
typedef unsigned long NSUInteger;
#else
//typedef int NSInteger;
//typedef unsigned int NSUInteger;
#endif
#endif

//! \brief Used to store buffers in collections.

// Using djb2 hashing algorithm by Bernstein. Found at
// http://www.cse.yorku.ca/~oz/hash.html
- (NSUInteger)hash
{
	pthread_mutex_lock(&bufferMutex);
	NSUInteger ret = 5381;
	int i;
	
	for(i = 0; i < size; ++i){
		ret = ((ret << 5) + ret) + rawData[i];
	}
	
	pthread_mutex_unlock(&bufferMutex);
	return ret;
}

#ifdef KEEP_UNDEFINED
#pragma mark Accessors
#endif

//! \brief Sets the buffer's position to the specified position.
//! \returns YES if the position was within the buffer's bounds, NO otherwise.

- (BOOL)setPosition:(int64_t)newPosition
{
	pthread_mutex_lock(&bufferMutex);
	BOOL ret = NO;
	if(newPosition >= 0 && newPosition <= size){
		position = newPosition;
		ret = YES;
	}
	
	pthread_mutex_unlock(&bufferMutex);
	return ret;
}

//! \returns the buffer's current position.

- (int64_t)position
{
	pthread_mutex_lock(&bufferMutex);
	uint64_t ret = position;
	pthread_mutex_unlock(&bufferMutex);
	return ret;
}

//! \returns YES if the last read operation was successful, NO otherwise.

- (BOOL)readSucceeded
{
	BOOL* readSucceeded = (BOOL*) pthread_getspecific(privateReadSucceededKey);
	if(readSucceeded == NULL){
		readSucceeded = (BOOL*) malloc(sizeof(*readSucceeded));
		*readSucceeded = NO;
		pthread_setspecific(privateReadSucceededKey, readSucceeded);
	}
	return *readSucceeded;
}

//! \returns the total size of the buffer.

- (int64_t)size
{
	pthread_mutex_lock(&bufferMutex);
	int64_t ret = size;
	pthread_mutex_unlock(&bufferMutex);
	return ret;
}

//! \returns the number of bytes between the position and the end of the buffer.

- (int64_t)remainingSize
{
	pthread_mutex_lock(&bufferMutex);
	int64_t ret = size - position;
	pthread_mutex_unlock(&bufferMutex);
	return ret;
}

#ifdef KEEP_UNDEFINED
#pragma mark Deallocation
#endif

- (void)dealloc
{
	if(rawData != NULL){
		free(rawData);
	}
	
	int i;
	for(i = 0; i < numPrivateRetainedPointers; ++i){
		free(privateRetainedPointers[i]);
	}
	
	if(privateRetainedPointers != NULL){
		free(privateRetainedPointers);
	}
	
	pthread_mutex_destroy(&bufferMutex);
	
	[super dealloc];
}

@end

@implementation BTLSocketBuffer (Protected)

- (void)protectedSetReadSucceeded:(BOOL)aBool
{
	BOOL* readSucceeded = (BOOL*) pthread_getspecific(privateReadSucceededKey);
	if(readSucceeded == NULL){
		readSucceeded = (BOOL*) malloc(sizeof(*readSucceeded));
	}
	
	*readSucceeded = aBool;
	pthread_setspecific(privateReadSucceededKey, readSucceeded);
}

@end

@implementation BTLSocketBuffer (Private)

#ifdef KEEP_UNDEFINED
#pragma mark Getting Strings
#endif

//! \sa getNullTerminatedString

- (char*)privateGetNullTerminatedString
{
	char* ret = NULL;
	int length = strlen(&(rawData[position]));
	
	[self protectedSetReadSucceeded:NO];
	
	if(position + length < size){
		++length;
		ret = (char*) malloc(sizeof(char) * length);
		if(ret == NULL){
			return NULL;
		}
		
		memcpy(ret, &(rawData[position]), length);
		position += length;
		[self protectedSetReadSucceeded:YES];
	}
	
	return ret;
}

//! \sa getStringTerminatedByLinebreak

- (char*)privateGetStringTerminatedByLinebreak
{
	[self protectedSetReadSucceeded:NO];
	char* ret = NULL;
	int length = 0;
	while(position + length <= size && (rawData[position + length] != '\r' &&  rawData[position + length] != '\n')){
		++length;
	}
	
	if(rawData[position + length] == '\r' || rawData[position + length] == '\n'){
		ret = [self privateGetStringOfSize:length];
	}
	
	if(rawData[position] == '\r'){
		++position;
		if(rawData[position] == '\n'){
			++position;
		}
	}else if(rawData[position] == '\n'){
		++position;
	}
	
	return ret;
}

//! \sa getStringTerminatedBy:

- (char*)privateGetStringTerminatedBy:(char*)aTerminal includeTerminal:(BOOL)aBool
{
	[self protectedSetReadSucceeded:NO];
	
	if(aTerminal == NULL || strcmp(aTerminal, "") == 0){
		return NULL;
	}
	
	char* ret = NULL;
	
	int terminalLength = strlen(aTerminal);
	int terminalIndex = 0;
	int length = size - position;
	
	int i;
	for(i = 0; i < length; ++i){
		if(terminalIndex >= terminalLength){
			break;
		}
		if(aTerminal[terminalIndex] == rawData[position + i]){
			++terminalIndex;
		}else{
			terminalIndex = 0;
		}
	}
	
	if(terminalIndex >= terminalLength){
		[self protectedSetReadSucceeded:YES];
		if(aBool == YES){
			ret = [self privateGetStringOfSize:i];
		}else{
			ret = [self privateGetStringOfSize:i - terminalLength];
			position += terminalLength;
		}
	}
	
	return ret;
}

//! \sa getStringOfSize:

- (char*)privateGetStringOfSize:(int64_t)theSize
{
	[self protectedSetReadSucceeded:NO];
	
	if(theSize <= 0 || INT64_MAX - theSize < position){ // Overflow
		return NULL;
	}
	
	char* ret = NULL;
	int length = size - position;
	
	if(theSize <= length){
		ret = (char*) malloc(sizeof(char) * (theSize + 1));
		if(ret == NULL){
			return NULL;
		}
		
		memset(ret, 0, theSize + 1);
		memcpy(ret, &(rawData[position]), theSize);
		position += theSize;
		[self protectedSetReadSucceeded:YES];
	}
	
	return ret;
}

#ifdef KEEP_UNDEFINED
#pragma mark Memory Management
#endif

//! \brief Adds an object to a list of pointers to be freed using the free()
//! function when the buffer is deallocated.

- (BOOL)privateAddRetainedPointers:(void*)aPointer
{
	if(numPrivateRetainedPointers == 0){
		privateRetainedPointers = (void**) malloc(sizeof(void*));
		if(privateRetainedPointers == NULL){
			return NO;
		}
	}else{
		void** temp = (void**) realloc(privateRetainedPointers, (numPrivateRetainedPointers + 1) * sizeof(void*));
		if(temp != NULL){
			privateRetainedPointers = temp;
		}else{
			return NO;
		}
	}
	
	privateRetainedPointers[numPrivateRetainedPointers] = aPointer;
	
	++numPrivateRetainedPointers;
	return YES;
}

@end

#ifdef KEEP_UNDEFINED
#pragma mark Network Order Functions
#endif

//! \brief Converts data of the specified length from host byte-order to network
//! byte order.

void* htonx(void* v, int length)
{
	return ntohx(v, length);
}

//! \brief Converts data of the specified length from netowrk byte-order to host
//! byte order.

void* ntohx(void* v, int length)
{
#if BYTE_ORDER == LITTLE_ENDIAN
	return flip(v, length);
#else
	void* ret = (void*) malloc(length);
	if(ret == NULL){
		return NULL;
	}
	
	memcpy(ret, v, length);
	return ret;
#endif
}

//! \brief Swaps the endiness of data of the specified length.

void* flip(void* v, int length)
{
	char* ret = (char*) malloc(length);
	if(ret == NULL){
		return NULL;
	}
	
	memcpy(ret, v, length);
	int start = 0;
	int end = length - 1;
	while(start < end){
		char c = ret[start];
		ret[start] = ret[end];
		ret[end] = c;
		++start;
		--end;
	}
	return ret;
}
