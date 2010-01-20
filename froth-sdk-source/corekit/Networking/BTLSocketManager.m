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

#import "BTLSocketManager.h"
#import "BTLSocketManager+Protected.h"

//! The BTLSocketManager class manages a set of connected sockets, connecting
//! sockets, and listening sockets, updrating them each time the select()
//! method is called.

@implementation BTLSocketManager

#ifdef KEEP_UNDEFINED
#pragma mark Initialization
#endif

- (id)init
{
	self = [super init];
	protectedConnectedSockets = [[NSMutableArray alloc] init];
	protectedConnectingSockets = [[NSMutableArray alloc] initWithCapacity:1];
	protectedListeningSockets = [[NSMutableArray alloc] initWithCapacity:1];
	privateHighestConnectedSocket = 0;
	FD_ZERO(&privateConnectedSocketSet);
	privateHighestListeningSocket = 0;
	FD_ZERO(&privateListeningSocketSet);
	
	pthread_mutex_init(&connectedAddMutex, NULL);
	pthread_mutex_init(&connectedRemoveMutex, NULL);
	pthread_mutex_init(&connectingAddMutex, NULL);
	pthread_mutex_init(&connectingRemoveMutex, NULL);
	pthread_mutex_init(&listeningAddMutex, NULL);
	pthread_mutex_init(&listeningRemoveMutex, NULL);
	
	return self;
}

#ifdef KEEP_UNDEFINED
#pragma mark Socket Management
#endif

- (void)addConnectedSocket:(BTLSocket*)aSocket
{
	pthread_mutex_lock(&connectedAddMutex);
	if(![[self protectedConnectedSockets] containsObject:aSocket]){
		[[self protectedConnectedSockets] addObject:aSocket];
	}
	
	if([aSocket socketDescriptor] > privateHighestConnectedSocket){
		privateHighestConnectedSocket = [aSocket socketDescriptor];
	}
	FD_SET([aSocket socketDescriptor], &privateConnectedSocketSet);
	pthread_mutex_unlock(&connectedAddMutex);
}

- (void)removeConnectedSocket:(BTLSocket*)aSocket
{
	pthread_mutex_lock(&connectedRemoveMutex);
	pthread_mutex_lock(&connectedAddMutex);
	FD_CLR([aSocket socketDescriptor], &privateConnectedSocketSet);
	privateHighestConnectedSocket = 0;
	
	[[self protectedConnectedSockets] removeObject:aSocket];
	
	BTLSocket* socket;
	{
		int i;
		int count = [protectedConnectedSockets count];
		for(i = 0; i < count; ++i){
			socket = [protectedConnectedSockets objectAtIndex:i];
			if([socket socketDescriptor] > privateHighestConnectedSocket){
				privateHighestConnectedSocket = [socket socketDescriptor];
			}
		}
	}
	pthread_mutex_unlock(&connectedAddMutex);
	pthread_mutex_unlock(&connectedRemoveMutex);
}

- (void)addListeningSocket:(BTLConnectionOrientedSocket*)aSocket
{
	pthread_mutex_lock(&listeningAddMutex);
	if(![[self protectedListeningSockets] containsObject:aSocket]){
		[[self protectedListeningSockets] addObject:aSocket];
	}
	
	if([aSocket socketDescriptor] > privateHighestListeningSocket){
		privateHighestListeningSocket = [aSocket socketDescriptor];
	}
	FD_SET([aSocket socketDescriptor], &privateListeningSocketSet);
	pthread_mutex_unlock(&listeningAddMutex);
}

- (void)removeListeningSocket:(BTLConnectionOrientedSocket*)aSocket
{
	pthread_mutex_lock(&listeningRemoveMutex);
	pthread_mutex_lock(&listeningAddMutex);
	FD_CLR([aSocket socketDescriptor], &privateListeningSocketSet);
	privateHighestListeningSocket = 0;
	
	[[self protectedListeningSockets] removeObject:aSocket];
	
	BTLSocket* socket;
	{
		int i;
		int count = [protectedListeningSockets count];
		for(i = 0; i < count; ++i){
			socket = [protectedListeningSockets objectAtIndex:i];
			if([socket socketDescriptor] > privateHighestListeningSocket){
				privateHighestListeningSocket = [socket socketDescriptor];
			}
		}
	}
	pthread_mutex_unlock(&listeningAddMutex);
	pthread_mutex_unlock(&listeningRemoveMutex);
}

- (void)addConnectingSocket:(BTLConnectionOrientedSocket*)aSocket
{
	pthread_mutex_lock(&connectingAddMutex);
	if(![[self protectedConnectingSockets] containsObject:aSocket]){
		[[self protectedConnectingSockets] addObject:aSocket];
	}
	pthread_mutex_unlock(&connectingAddMutex);
}

- (void)removeConnectingSocket:(BTLConnectionOrientedSocket*)aSocket
{
	pthread_mutex_lock(&connectingRemoveMutex);
	pthread_mutex_lock(&connectingAddMutex);
	[[self protectedConnectingSockets] removeObject:aSocket];
	pthread_mutex_unlock(&connectingAddMutex);
	pthread_mutex_unlock(&connectingRemoveMutex);
}

//! \brief Removes the socket from the manager completely.

- (void)removeSocket:(BTLSocket*)aSocket
{	
	[self removeListeningSocket:(BTLConnectionOrientedSocket*) aSocket];
	[self removeConnectingSocket:(BTLConnectionOrientedSocket*) aSocket];
	[self removeConnectedSocket:(BTLConnectionOrientedSocket*) aSocket];
}

#ifdef KEEP_UNDEFINED
#pragma mark Deallocation
#endif

//! \brief Updates the sockets.
//!
//! This method should be called often. Managed sockets will not recieve data or
//! finish pending connections until this method is called. NSTimer can be used
//! to call this method on a regular basis.

- (void)select
{
	BTLSocket* currentObject = nil;
	pthread_mutex_lock(&listeningRemoveMutex);
	pthread_mutex_lock(&listeningAddMutex);
	fd_set set = privateListeningSocketSet;
	pthread_mutex_unlock(&listeningAddMutex);
	struct timeval timeout;
	memset(&timeout, 0, sizeof(struct timeval));
	while(select(privateHighestListeningSocket + 1, &set, NULL, NULL, &timeout) > 0){
		int i;
		int count = [protectedListeningSockets count];
		for(i = 0; i < count; ++i){
			currentObject = [protectedListeningSockets objectAtIndex:i];
			if(FD_ISSET([currentObject socketDescriptor], &set)){
				BTLConnectionOrientedSocket* newSocket = [((BTLConnectionOrientedSocket*) currentObject) accept];
				[newSocket release];
			}
		}
		pthread_mutex_lock(&listeningAddMutex);
		set = privateListeningSocketSet;
		pthread_mutex_unlock(&listeningAddMutex);
	}
	pthread_mutex_unlock(&listeningRemoveMutex);
	
	NSMutableArray* newlyConnected = [[NSMutableArray alloc] init];
	pthread_mutex_lock(&connectingRemoveMutex);
	{
		int i;
		int count = [protectedConnectingSockets count];
		for(i = 0; i < count; ++i){
			currentObject = [protectedConnectingSockets objectAtIndex:i];
			[currentObject connectToAddress:nil withTimeout:nil];
			if([currentObject isConnected]){
				[newlyConnected addObject:currentObject];
			}
		}
	}
	pthread_mutex_unlock(&connectingRemoveMutex);
	
	{
		int i;
		int count = [newlyConnected count];
		for(i = 0; i < count; ++i){
			[self removeConnectingSocket:[newlyConnected objectAtIndex:i]];
		}
	}
	[newlyConnected release];
	
	NSMutableArray* newlyDisconnected = [[NSMutableArray alloc] init];
	pthread_mutex_lock(&connectedRemoveMutex);
	pthread_mutex_lock(&connectedAddMutex);
	set = privateConnectedSocketSet;
	pthread_mutex_unlock(&connectedAddMutex);
	while(select(privateHighestConnectedSocket + 1, &set, NULL, NULL, &timeout) > 0){
		int i;
		int count = [protectedConnectedSockets count];
		for(i = 0; i < count; ++i){
			currentObject = [protectedConnectedSockets objectAtIndex:i];
			if(FD_ISSET([currentObject socketDescriptor], &set)){
				[currentObject read];
				if(![currentObject isConnected] && ![newlyDisconnected containsObject:currentObject]){
					FD_CLR([currentObject socketDescriptor], &privateConnectedSocketSet);
					[newlyConnected addObject:currentObject];
				}
			}
		}
		pthread_mutex_lock(&connectedAddMutex);
		set = privateConnectedSocketSet;
		pthread_mutex_unlock(&connectedAddMutex);
	}
	pthread_mutex_unlock(&connectedRemoveMutex);
	
	{
		int i;
		int count = [newlyDisconnected count];
		for(i = 0; i < count; ++i){
			[self removeConnectedSocket:[newlyDisconnected objectAtIndex:i]];
		}
	}
	[newlyDisconnected release];
}

#ifdef KEEP_UNDEFINED
#pragma mark Deallocation
#endif

- (void)dealloc
{
	if(protectedConnectedSockets != nil){
		int i;
		int count = [protectedConnectedSockets count];
		for(i = 0; i < count; ++i){
			[[protectedConnectedSockets objectAtIndex:i] setManager:nil];
		}
		[protectedConnectedSockets release];
	}
	
	if(protectedListeningSockets != nil){
		int i;
		int count = [protectedListeningSockets count];
		for(i = 0; i < count; ++i){
			[[protectedListeningSockets objectAtIndex:i] setManager:nil];
		}
		[protectedListeningSockets release];
	}
	
	if(protectedConnectingSockets != nil){
		int i;
		int count = [protectedConnectingSockets count];
		for(i = 0; i < count; ++i){
			[[protectedConnectingSockets objectAtIndex:i] setManager:nil];
		}
		[protectedConnectingSockets release];
	}
	
	pthread_mutex_destroy(&connectedAddMutex);
	pthread_mutex_destroy(&connectedRemoveMutex);
	pthread_mutex_destroy(&connectingAddMutex);
	pthread_mutex_destroy(&connectingRemoveMutex);
	pthread_mutex_destroy(&listeningAddMutex);
	pthread_mutex_destroy(&listeningRemoveMutex);
	
	[super dealloc];
}

@end

@implementation BTLSocketManager (Protected)

#ifdef KEEP_UNDEFINED
#pragma mark Protected Accessors
#endif

- (NSMutableArray*)protectedListeningSockets
{
	return protectedListeningSockets;
}

- (NSMutableArray*)protectedConnectingSockets
{
	return protectedConnectingSockets;
}

- (NSMutableArray*)protectedConnectedSockets
{
	return protectedConnectedSockets;
}

@end
