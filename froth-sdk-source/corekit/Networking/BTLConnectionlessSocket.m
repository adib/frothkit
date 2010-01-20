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

#import "BTLConnectionlessSocket.h"
#import "BTLSocket+Protected.h"
#import "BTLSocketManager.h"

@interface BTLConnectionlessSocket (Private)

#ifdef KEEP_UNDEFINED
#pragma mark Private Accessors
#endif

- (NSMutableDictionary*)privateHandlerLists;

@end

//! The BTLConnectionLessSocket class communicates with one or more remote
//! sockets using a connectionless protocol.
//!
//! This class does implement BTLSocket methods such as
//! connectToAddress:withTimeout: but they are called internally to maintain a
//! list of which addresses the connectionless-socket is communicating with.
//! They can be called manually to add or remove addresses to the remoteSockets
//! NSArray. In addition, these methods use the result of
//! <BTlSocketDelegate>::shouldConnectToAddress:sender:() to determine whether
//! or not to connect to a remote address. The class will not read or write to
//! and from a disallowed address.

@implementation BTLConnectionlessSocket

#ifdef KEEP_UNDEFINED
#pragma mark Initializers
#endif

- (id)init
{
	self = [super init];
	privateHandlerLists = [NSMutableDictionary new];
	BTLSocketHandlerList* newMasterList = [BTLSocketHandlerList new];
	[self setMasterHandlerList:newMasterList];
	[newMasterList release];
	return self;
}

- (id)initWithAddressFamily:(sa_family_t)aFamily type:(int)aType protocol:(int)aProtocol
{
	self = [super initWithAddressFamily:aFamily type:aType protocol:aProtocol];
	privateHandlerLists = [[NSMutableDictionary alloc] initWithCapacity:1];
	BTLSocketHandlerList* newMasterList = [BTLSocketHandlerList new];
	[self setMasterHandlerList:newMasterList];
	[newMasterList release];
	return self;
}

#ifdef KEEP_UNDEFINED
#pragma mark Connecting and Disconnecting
#endif

- (BOOL)connectToAddress:(BTLSocketAddress*)anAddress withTimeout:(NSNumber*)timeout
{
	if(delegate != nil && [delegate respondsToSelector:@selector(shouldConnectToAddress:sender:)]
	   && [delegate shouldConnectToAddress:anAddress sender:self] == NO){
		return NO;
	}
	
	if([self handlerListForAddress:anAddress] != nil){
		return YES;
	}
	
	[self protectedCreateNewHandlerListForAddress:anAddress];
	[[self handlerListForAddress:anAddress] connectionOpenedToAddress:anAddress];
	
	if([[self remoteAddresses] count] == 1){
		[self protectedSetCurrentState:BTLSocketConnected];
	}
	return YES;
}

- (void)finishedClosingConnectionToAddress:(BTLSocketAddress*)anAddress
{
	[self protectedRemoveHandlerListForAddress:anAddress];
	
	if([[self remoteAddresses] count] < 1){
		[self protectedSetCurrentState:BTLSocketDisconnected];
		[self protectedRemoveHandlerListForAddress:anAddress];
		if(manager != nil){
			[manager removeConnectedSocket:self];
		}
	}
}

#ifdef KEEP_UNDEFINED
#pragma mark Reading and Writing
#endif

- (void)readData:(BTLSocketBuffer*)someData fromAddress:(BTLSocketAddress*)anAddress
{
	[self protectedSetRemoteAddress:anAddress];
	
	BTLSocketHandlerList* handlerList = [self handlerListForAddress:anAddress];
	
	if(handlerList == nil){
		[self connectToAddress:anAddress withTimeout:nil];
		handlerList = [self handlerListForAddress:anAddress];
	}
	
	if(handlerList != nil){
		[someData rewind];
		[handlerList readData:someData fromAddress:anAddress];
	}
}

- (BOOL)writeData:(BTLSocketBuffer*)someData toAddress:(BTLSocketAddress*)anAddress
{
	BTLSocketHandlerList* handlerList = [self handlerListForAddress:anAddress];
	
	if(handlerList == nil){
		[self connectToAddress:anAddress withTimeout:nil];
		handlerList = [self handlerListForAddress:anAddress];
	}
	
	if(handlerList != nil){
		[someData rewind];
		return [handlerList writeData:someData toAddress:anAddress];
	}
	
	return NO;
}

- (BOOL)canReadFromAddress:(BTLSocketAddress*)anAddress
{
	BTLSocketHandlerList* list = [self handlerListForAddress:anAddress]; 
	if(list != nil){
		return YES;
	}
	
	return [self addressFamily] == [anAddress family] && delegate != nil &&
		[delegate respondsToSelector:@selector(shouldConnectToAddress:sender:)] &&
		[delegate shouldConnectToAddress:anAddress sender:self];
}

- (BOOL)canWriteToAddress:(BTLSocketAddress*)anAddress
{
	BTLSocketHandlerList* list = [self handlerListForAddress:anAddress]; 
	if(list != nil){
		return [list canWrite];
	}
	
	return [self addressFamily] == [anAddress family] && delegate != nil &&
		[delegate respondsToSelector:@selector(shouldConnectToAddress:sender:)] &&
		[delegate shouldConnectToAddress:anAddress sender:self];
}

#ifdef KEEP_UNDEFINED
#pragma mark BTLSocketHandlerList Management
#endif

- (void)addHandlerToFront:(BTLSocketHandler*)aHandler forAddress:(BTLSocketAddress*)anAddress
{	
	if(anAddress == nil){
		NSEnumerator* enumerator = [[self privateHandlerLists] objectEnumerator];
		BTLSocketHandlerList* handlerList;
		
		while(handlerList = [enumerator nextObject]){
			[handlerList addHandlerToFront:aHandler];
		}
	}else{
		BTLSocketHandlerList* handlerList = [self handlerListForAddress:anAddress];
		[handlerList addHandlerToFront:aHandler];
	}
}

- (void)addHandlerToEnd:(BTLSocketHandler*)aHandler forAddress:(BTLSocketAddress*)anAddress
{
	if(anAddress == nil){
		NSEnumerator* enumerator = [[self privateHandlerLists] objectEnumerator];
		BTLSocketHandlerList* handlerList;
		
		while(handlerList = [enumerator nextObject]){
			[handlerList addHandlerToEnd:aHandler];
		}
	}else{
		BTLSocketHandlerList* handlerList = [self handlerListForAddress:anAddress];
		[handlerList addHandlerToEnd:aHandler];
	}
}

- (void)setHandlerList:(BTLSocketHandlerList*)aList forAddress:(BTLSocketAddress*)anAddress
{
	if(aList == nil || [self handlerListForAddress:anAddress] == nil){
		return;
	}
	
	BTLSocketHandlerList* copiedList = [aList copy];
	[[self privateHandlerLists] setObject:copiedList forKey:anAddress];
	[copiedList release];
	if([[self remoteAddresses] count] == 1){
		[self protectedSetCurrentState:BTLSocketConnected];
	}
	
	[[self handlerListForAddress:anAddress] setSocket:self];
}

- (BTLSocketHandlerList*)handlerListForAddress:(BTLSocketAddress*)anAddress
{	
	return [[self privateHandlerLists] objectForKey:anAddress];
}

- (void)resetHandlerListForAddress:(BTLSocketAddress*)anAddress
{
	if(anAddress != nil){
		if([self masterHandlerList] != nil){
			[self setHandlerList:[self masterHandlerList] forAddress:anAddress];
		}else{
			BTLSocketHandlerList* temp = [BTLSocketHandlerList new];
			[self setHandlerList:temp forAddress:anAddress];
			[temp release];
		}
	}else{
		NSEnumerator* enumerator = [[self remoteAddresses] objectEnumerator];
		BTLSocketAddress* currentAddress;
		
		while(currentAddress = [enumerator nextObject]){
			[self setHandlerList:[self masterHandlerList] forAddress:currentAddress];
		}
	}
}

#ifdef KEEP_UNDEFINED
#pragma mark Accessors
#endif

- (NSArray*)remoteAddresses
{
	return [[self privateHandlerLists] allKeys];
}

- (void)setManager:(id)aManager
{
	if(manager != nil){
			[manager removeSocket:self];
	}
	
	[super setManager:aManager];
	[manager addConnectedSocket:self];
}

#ifdef KEEP_UNDEFINED
#pragma mark Deallocation
#endif

- (void)dealloc
{
	[privateHandlerLists release];
	[super dealloc];
}

@end

@implementation BTLConnectionlessSocket (Protected)

#ifdef KEEP_UNDEFINED
#pragma mark Protected BTLSocketHandlerList Management
#endif

- (void)protectedAddHandlerList:(BTLSocketHandlerList*)aList forAddress:(BTLSocketAddress*)anAddress
{
	if([self handlerListForAddress:anAddress] != nil){
		return;
	}
	
	[aList setSocket:self];
	[[self privateHandlerLists] setObject:aList forKey:anAddress];
}

- (void)protectedRemoveHandlerListForAddress:(BTLSocketAddress*)anAddress
{
	if([self handlerListForAddress:anAddress] == nil){
		return;
	}
	
	[[self privateHandlerLists] removeObjectForKey:anAddress];
}

@end

@implementation BTLConnectionlessSocket (Private)

#ifdef KEEP_UNDEFINED
#pragma mark Private Accessors
#endif

- (NSMutableDictionary*)privateHandlerLists
{
	return privateHandlerLists;
}

@end
