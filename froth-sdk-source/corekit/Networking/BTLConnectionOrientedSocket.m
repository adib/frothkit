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

#import "BTLConnectionOrientedSocket.h"
#import "BTLSocket+Protected.h"
#import "BTLSocketManager.h"

@interface BTLConnectionOrientedSocket (Private)

#ifdef KEEP_UNDEFINED
#pragma mark Private Accessors
#endif

- (BTLSocketHandlerList*)privateHandlerList;

@end

//! The BTLConnectionOrientedSocket class communicates with one remote socket
//! using a connection-oriented protocol.
//!
//! This class contains two methods, listenWithBacklog:() and accept() for
//! listening for incoming connections. These are abstract methods which should
//! be implemented by subclasses.

@implementation BTLConnectionOrientedSocket

#ifdef KEEP_UNDEFINED
#pragma mark Initializers
#endif

- (id)init
{
	self = [super init];
	BTLSocketHandlerList* temp = [BTLSocketHandlerList new];
	[self setHandlerList:temp forAddress:nil];
	[temp release];
	return self;
}

- (id)initWithAddressFamily:(sa_family_t)aFamily type:(int)aType protocol:(int)aProtocol
{
	self = [super initWithAddressFamily:aFamily type:aType protocol:aProtocol];
	BTLSocketHandlerList* temp = [BTLSocketHandlerList new];
	[self setHandlerList:temp forAddress:nil];
	[temp release];
	return self;
}

- (id)initSocketConnectedTo:(BTLSocketAddress*)anAddress withSocketDescriptor:(int)aSocketDescriptor
				   delegate:(id)aDelegate handlerList:(BTLSocketHandlerList*)aList manager:(BTLSocketManager*)aManager
{
	socketDescriptor = aSocketDescriptor;
	[super init];
	
	if(aDelegate != nil && (![aDelegate isKindOfClass:[BTLSocket class]])){
		[self setDelegate:aDelegate];
	}else{
		[self setDelegate:self];
	}
	
	if(aList != nil){
		[self setHandlerList:aList forAddress:anAddress];
	}else{
		BTLSocketHandlerList* temp = [BTLSocketHandlerList new];
		[self setHandlerList:temp forAddress:anAddress];
		[temp release];
	}
	
	[self protectedSetCurrentState:BTLSocketConnected];
	[self protectedSetRemoteAddress:anAddress];
	
	struct sockaddr_storage temp;
	socklen_t tempLength = sizeof(struct sockaddr_storage);
	getsockname(aSocketDescriptor, (struct sockaddr*) &temp, &tempLength);
	[self protectedSetLocalAddress:[BTLSocketAddress addressWithSockaddrStruct:&temp ofSize:tempLength]];
	
	[[self handlerListForAddress:anAddress] connectionOpenedToAddress:anAddress];
	
	if(aManager != nil){
		[self setManager:aManager];
		[aManager addConnectedSocket:self];
	}
	
	return self;
}

#ifdef KEEP_UNDEFINED
#pragma mark Reading and Writing
#endif

- (void)readData:(BTLSocketBuffer*)someData fromAddress:(BTLSocketAddress*)anAddress
{
	if([self handlerListForAddress:anAddress] == nil){
		[self protectedCreateNewHandlerListForAddress:anAddress];
	}
	
	[someData rewind];
	[[self handlerListForAddress:anAddress] readData:someData fromAddress:anAddress];
}

- (BOOL)canReadFromAddress:(BTLSocketAddress*)anAddress
{
	return [self isConnected] && anAddress == [self remoteAddress];
}

- (BOOL)writeData:(BTLSocketBuffer*)someData toAddress:(BTLSocketAddress*)anAddress
{
	if([self handlerListForAddress:anAddress] == nil){
		[self protectedCreateNewHandlerListForAddress:anAddress];
	}
	
	[someData rewind];
	return [[self handlerListForAddress:anAddress] writeData:someData toAddress:anAddress];
}

- (BOOL)canWriteToAddress:(BTLSocketAddress*)anAddress
{	
	if(anAddress != [self remoteAddress]){
		return NO;
	}
	
	if([self handlerListForAddress:anAddress] != nil){
		[self protectedCreateNewHandlerListForAddress:anAddress];
	}
	
	return [[self handlerListForAddress:[self remoteAddress]] canWrite];
}

#ifdef KEEP_UNDEFINED
#pragma mark Listening For and Accepting Connections
#endif

//! \brief This method causes the socket to listen for incoming connections
//! until it is closed.
//!
//! The socket will queue up to backlog connections. Every time
//! BTLConnectionOrientedSocket::Accept() is called, one connection will be
//! removed from the backlog, if present. When the backlog is full, connections
//! will not be queued for acceptance.

- (BOOL)listenWithBacklog:(int)backlog
{
	return NO;
}

//! \brief accepts an incmoinc connection.
//!
//! This method calls <BTLSocketDelegate>::shouldConnectToAddress:sender:() to
//! determine whether or not to accept the connection.

- (BTLConnectionOrientedSocket*)accept
{
	return nil;
}

#ifdef KEEP_UNDEFINED
#pragma mark BTLSocketHandlerList Management
#endif

- (void)addHandlerToFront:(BTLSocketHandler*)aHandler forAddress:(BTLSocketAddress*)anAddress
{
	if([self handlerListForAddress:anAddress] == nil){
		[self protectedCreateNewHandlerListForAddress:anAddress];
	}
	
	[[self handlerListForAddress:anAddress] addHandlerToFront:aHandler];
}

- (void)addHandlerToEnd:(BTLSocketHandler*)aHandler forAddress:(BTLSocketAddress*)anAddress
{
	if([self handlerListForAddress:anAddress] == nil){
		[self protectedCreateNewHandlerListForAddress:anAddress];
	}
	
	[[self handlerListForAddress:anAddress] addHandlerToEnd:aHandler];
}

- (void)setHandlerList:(BTLSocketHandlerList*)aList forAddress:(BTLSocketAddress*)anAddress
{
	if(aList == nil || privateHandlerList == aList){
		return;
	}
	[privateHandlerList release];

	privateHandlerList = [aList copy];
	
	[privateHandlerList setSocket:self];
}

- (BTLSocketHandlerList*)handlerListForAddress:(BTLSocketAddress*)anAddress
{
	return [self privateHandlerList];
}

- (void)resetHandlerListForAddress:(BTLSocketAddress*)anAddress
{
	if([self masterHandlerList] != nil){
		[self setHandlerList:[self masterHandlerList] forAddress:anAddress];
	}else{
		BTLSocketHandlerList* temp = [BTLSocketHandlerList new];
		[self setHandlerList:temp forAddress:anAddress];
		[temp release];
	}
}

#ifdef KEEP_UNDEFINED
#pragma mark Accessors
#endif

- (NSArray*)remoteAddresses
{
	return [NSArray arrayWithObject:[self remoteAddress]];
}

- (void)dealloc
{
	[self closeConnectionToAddress:remoteAddress];
	
	if(privateHandlerList != nil){
		[privateHandlerList release];
	}
	
	[super dealloc];
}

@end

@implementation BTLConnectionOrientedSocket (Protected)

#ifdef KEEP_UNDEFINED
#pragma mark Protected BTLSocketHandlerList Management
#endif

- (void)protectedAddHandlerList:(BTLSocketHandlerList*)aList forAddress:(BTLSocketAddress*)anAddress
{
	if([self handlerListForAddress:anAddress] != nil){
		return;
	}
	
	[self setHandlerList:aList forAddress:anAddress];
}

- (void)protectedRemoveHandlerListForAddress:(BTLSocketAddress*)anAddress
{
	if([self handlerListForAddress:anAddress] == nil){
		return;
	}
	
	[[self handlerListForAddress:anAddress] release];
	privateHandlerList = nil;
}

@end

@implementation BTLConnectionOrientedSocket (Private)

#ifdef KEEP_UNDEFINED
#pragma mark Private Accessors
#endif

- (BTLSocketHandlerList*)privateHandlerList
{
	return privateHandlerList;
}

@end
