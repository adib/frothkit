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

#import "BTLSocketAddress.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <netdb.h>

static NSMutableDictionary* BTLSocketAddressSubclassDict;

//! The BTLSocketAddress class encaluslates an address which can be bound to a
//! socket.
//!
//! The BTLSockets framework contains subclasses for IP addresses, but other
//! addresses, like UNIX domain addresses can be added.

@implementation BTLSocketAddress

#ifdef KEEP_UNDEFINED
#pragma mark Initializers
#endif

- (id)init
{
	self = [super init];
	memset(&sockaddr, 0, sizeof(struct sockaddr_storage));
	return self;
}

//! \brief Creates a new BTLSocketAddress subclass from the specified sockaddr
//! struct of the specified size.

+ (id)addressWithSockaddrStruct:(struct sockaddr_storage*)aSockaddr ofSize:(socklen_t)theSize
{
	if(aSockaddr == NULL){
		return nil;
	}
	
	id class = [self classForFamily:aSockaddr->ss_family];
	if(class == nil){
		return nil;
	}
	
	id instance = [class new];
	
	[instance setSockaddr:aSockaddr ofSize:theSize];
	
	return instance;
}

#ifdef KEEP_UNDEFINED
#pragma mark Copying
#endif

- (id)copyWithZone:(NSZone*)zone
{
	return [[self class] addressWithSockaddrStruct:&sockaddr ofSize:size];
}

#ifdef KEEP_UNDEFINED
#pragma mark Equality Methods
#endif

- (BOOL)isEqual:(id)anObject
{
	if(anObject == nil){
		return NO;
	}
	
	if(anObject == self){
		return YES;
	}
	
	if([anObject isKindOfClass:[self class]]){
		return [self isEqualToSockaddrStruct:[anObject sockaddr]];
	}
	
	return NO;
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
	NSUInteger ret = 5381;
	int i;
	
	for(i = 0; i < size; ++i){
		ret = ((ret << 5) + ret) + ((char*) &sockaddr)[i];
	}
	
	return ret;
}

//! \returns YES if the BTLSocketAddress contains the same information as the
//! sockaddr struct, NO otherwise.

- (BOOL)isEqualToSockaddrStruct:(const struct sockaddr_storage*)aSockaddr
{	
	int i;
	for(i = 0; i < size; ++i){
		if(((char*) &sockaddr)[i] != ((char*) aSockaddr)[i]){
			return NO;
		}
	}
	
	return YES;
}

#ifdef KEEP_UNDEFINED
#pragma mark Accessors
#endif

//! \returns the address of the internal sockaddr struct.
//!
//! \sa BTLSocket::initWithAddressFamily:type:potocol:

- (sa_family_t)family
{
	return sockaddr.ss_family;
}

//! \brief Sets the internal sockaddr struct.

- (void)setSockaddr:(struct sockaddr_storage*)aSockaddr ofSize:(socklen_t)theSize
{
	memset(&sockaddr, 0, sizeof(struct sockaddr_storage));
	memcpy(&sockaddr, aSockaddr, theSize);
	size = theSize;
}

//! \returns a non-modifiable reference to the internal sockaddr struct.

- (const struct sockaddr_storage*)sockaddr
{
	const struct sockaddr_storage* ret = &sockaddr;
	return ret;
}

//! \returns the size of the internal sockaddr struct in bytes.

- (socklen_t)size
{
	return size;
}

#ifdef KEEP_UNDEFINED
#pragma mark Class Methods
#endif

//! \returns the address family for the specific subclass of BTLSocketAddress.
//!
//! Each subclass should override this method to return the address family
//! associated with that subclass.

+ (sa_family_t)family
{
	return AF_UNSPEC;
}

//! \brief Registers the subclass of BTLSocketAddress's family with that
//! subclass.
//!
//! All subclasses should call this method at +load.

+ (void)registerWithSuperclass
{
	if(objc_getClass("NSMutableDictionary") == nil){
		[self performSelector:@selector(registerWithSuperclass)
				   withObject:nil
				   afterDelay:0.5];
	}else{		
		if(BTLSocketAddressSubclassDict == nil){
			BTLSocketAddressSubclassDict = [[NSMutableDictionary alloc] initWithCapacity:2];
		}
		NSString* familyRep = [[NSString alloc] initWithFormat:@"%d", [self family]];
		[BTLSocketAddressSubclassDict setObject:[self class] forKey:familyRep];
		[familyRep release];
	}
}

//! \returns the subclass associated with the specified family.

+ (id)classForFamily:(sa_family_t)aFamily
{
	if(BTLSocketAddressSubclassDict == nil){
		NSLog(@"+error no BTLSocketAddressSubclassDict [%s]:%i", __FILE__, __LINE__);
		return nil;
	}
	
	NSString* familyRep = [[NSString alloc] initWithFormat:@"%d", aFamily];
	id class = [BTLSocketAddressSubclassDict objectForKey:familyRep];
	[familyRep release];
	
	if(class != nil && [class isSubclassOfClass:[self class]]){
		return class;
	}
		
	return nil;
}

@end
