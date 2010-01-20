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

#import "BTLUDPSocket.h"
#import "BTLSocket+Protected.h"

//! The BTLUDPSocket class implements communications over the connectionless UDP
//! protocol.

@implementation BTLUDPSocket

#ifdef KEEP_UNDEFINED
#pragma mark Loading
#endif

+ (void)load
{
	[self registerWithSuperclass];
}

#ifdef KEEP_UNDEFINED
#pragma mark Reading and Writing
#endif

- (BTLSocketBuffer*)read
{	
	char buffer[66535];
	BTLSocketBuffer* ret = nil;
	
	struct sockaddr_storage address;
	unsigned int addressSize = sizeof(struct sockaddr_storage);
	
	int length = recvfrom(socketDescriptor, buffer, 66535, 0, (struct sockaddr*) &address, &addressSize);
	if(length > 0){
		BTLSocketBuffer* data = [BTLSocketBuffer new];
		[data addData:buffer ofSize:length];
		
		BTLSocketAddress* lastAddress = [BTLSocketAddress addressWithSockaddrStruct:&address ofSize:addressSize];
		
		[self readData:data fromAddress:lastAddress];
		[data autorelease];
		
		if(delegate == self){
			ret = privateBuffer;
			privateBuffer = nil;
		}
	}
	return ret;
}

- (void)finishedWritingData:(BTLSocketBuffer*)someData toAddress:(BTLSocketAddress*)anAddress
{
	sendto(socketDescriptor, [someData rawData], [someData size], 0,
		   (struct sockaddr*) [anAddress sockaddr], [anAddress size]);
}

#ifdef KEEP_UNDEFINED
#pragma mark Class Methods
#endif

+ (int)type
{
	return SOCK_DGRAM;
}

+ (int)protocol
{
	return 17; // Protocol number for UDP as defined in /etc/protocols
}

@end
