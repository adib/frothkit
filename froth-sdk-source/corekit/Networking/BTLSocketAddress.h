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
#import <sys/socket.h>

@interface BTLSocketAddress : NSObject {
	//! \brief The sockaddr struct used to store address data.
	struct sockaddr_storage sockaddr;
	
	//! \brief The size of the sockaddr struct in bytes.
	socklen_t size;
}

#ifdef KEEP_UNDEFINED
#pragma mark Initializers
#endif

+ (id)addressWithSockaddrStruct:(struct sockaddr_storage*)aSockaddr ofSize:(socklen_t)theSize;

#ifdef KEEP_UNDEFINED
#pragma mark Equality Methods
#endif

- (BOOL)isEqualToSockaddrStruct:(const struct sockaddr_storage*)aSockaddr;


#ifdef KEEP_UNDEFINED
#pragma mark Accessors
#endif

- (sa_family_t)family;
- (void)setSockaddr:(struct sockaddr_storage*)aSockaddr ofSize:(socklen_t)theSize;
- (const struct sockaddr_storage*)sockaddr;
- (socklen_t)size;

#ifdef KEEP_UNDEFINED
#pragma mark Class Methods
#endif

+ (sa_family_t)family;
+ (void)registerWithSuperclass;
+ (id)classForFamily:(sa_family_t)aFamily;

@end
