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

#import "BTLTCPSocket.h"
#import "BTLSocket+Protected.h"
#import "BTLSocketManager.h"
#import "BTLGetError.h"

#include <unistd.h>

//! The BTLTCPSocket class implements communications over the
//! connection-oriented TCP protocol.

@implementation BTLTCPSocket

#ifdef KEEP_UNDEFINED
#pragma mark Loading
#endif

+ (void)load
{
	[self registerWithSuperclass];
}

#ifdef KEEP_UNDEFINED
#pragma mark Connecting and Disconnecting
#endif

- (BOOL)connectToAddress:(BTLSocketAddress*)anAddress withTimeout:(NSNumber*)timeout
{
	if([self remoteAddress] != nil){
		anAddress = [self remoteAddress];
	}
	
	if(anAddress == nil){
		return NO;
	}
	
	if([self remoteAddress] == nil && delegate != nil){
		if([delegate respondsToSelector:@selector(shouldConnectToAddress:sender:)]
		   && [delegate shouldConnectToAddress:anAddress sender:self] == NO){
			[[self handlerListForAddress:anAddress] connectionFailedToAddress:anAddress];
			return NO;
		}
	}
	
	int ret = connect(socketDescriptor, (struct sockaddr*) [anAddress sockaddr], [anAddress size]);
	
	int error = 0;
	if(ret != 0){
		error = BTLGetError();
		if(error == EISCONN){
			ret = 0;
		}else if(error == EWOULDBLOCK || error == EINPROGRESS || error == EALREADY){
			[self protectedSetRemoteAddress:anAddress];
			if([self protectedCurrentState] != BTLSocketConnecting){
				[self protectedSetCurrentState:BTLSocketConnecting];
				privateRemainingTimeout = [timeout retain];
				privateLastConnectionAttempt = [[NSDate alloc] init];
				if(manager != nil){
					[manager addConnectingSocket:self];
				}
			}else if(privateRemainingTimeout != nil){
				NSDate* now = [[NSDate alloc] init];
				NSTimeInterval diff = [now timeIntervalSinceDate:privateLastConnectionAttempt];
				
				NSTimeInterval newTimeout = [privateRemainingTimeout doubleValue];
				newTimeout = newTimeout - diff;
				
				[privateRemainingTimeout release];
				privateRemainingTimeout = nil;
				if(privateLastConnectionAttempt != nil){
					[privateLastConnectionAttempt release];
					privateLastConnectionAttempt = nil;
				}
				
				if(newTimeout < 0.0){
					ret = 1;
				}else{
					privateRemainingTimeout = [[NSNumber alloc] initWithDouble:newTimeout];
					privateLastConnectionAttempt = now;
				}
			}else{
				ret = 1;
			}
		}else{
			ret = 1;
		}
	}
	
	if(ret == 0){
		if([self remoteAddress] == nil && anAddress != nil){
			[self protectedSetRemoteAddress:anAddress];
		}
		[[self handlerListForAddress:anAddress] connectionOpenedToAddress:anAddress];
		[self protectedSetCurrentState:BTLSocketConnected];
		if(manager != nil){
			[manager addConnectedSocket:self];
		}
	}else if(ret == 1){
		[[self handlerListForAddress:anAddress] connectionFailedToAddress:anAddress];
		if([self remoteAddress] != nil){
			[self protectedSetRemoteAddress:nil];
		}
		if(manager != nil){
			[manager removeConnectingSocket:self];
		}
	}
	
	if(ret == 0 || ret == 1){
		if(privateRemainingTimeout != nil){
			[privateRemainingTimeout release];
			privateRemainingTimeout = nil;
		}
		if(privateLastConnectionAttempt != nil){
			[privateLastConnectionAttempt release];
			privateLastConnectionAttempt = nil;
		}
	}
	
	return ret == 0;
}

- (void)finishedClosingConnectionToAddress:(BTLSocketAddress*)anAddress
{
#ifdef WIN32
	closesocket(socketDescriptor);
#else
	close(socketDescriptor);
#endif
	[self protectedSetCurrentState:BTLSocketDisconnected];
	
	if(manager != nil){
		[manager removeSocket:self];
		manager = nil;
	}
}

#ifdef KEEP_UNDEFINED
#pragma mark Reading and Writing
#endif

- (BTLSocketBuffer*)read
{
	BTLSocketBuffer* ret = nil;
	if([self isConnected]){
		char buffer[recieveBufferSize];
		int length = recv(socketDescriptor, buffer, recieveBufferSize, 0);
		if(length > 0){
			BTLSocketBuffer* data = [BTLSocketBuffer new];
			[data addData:buffer ofSize:length];

			while(length == 1024){
				length = recv(socketDescriptor, buffer, 1024, 0);
				[data addData:buffer ofSize:length];
			}
			
			[self readData:data fromAddress:[self remoteAddress]];
			[data autorelease];
			
			if(delegate == self){
				ret = privateBuffer;
				privateBuffer = nil;
			}
		}else if(length == 0){
			[[self handlerListForAddress:[self remoteAddress]] connectionClosedByRemoteAddress:[self remoteAddress]];
			[self protectedSetCurrentState:BTLSocketDisconnected];
		}
	}
	return ret;
}

- (void)finishedWritingData:(BTLSocketBuffer*)someData toAddress:(BTLSocketAddress*)anAddress
{
	send(socketDescriptor, [someData rawData], [someData size], 0);
}

#ifdef KEEP_UNDEFINED
#pragma mark Listening For and Accepting Connections
#endif

- (BOOL)listenWithBacklog:(int)backlog
{
	if([self isConnected]){
		return NO;
	}
	
	if(listen(socketDescriptor, backlog) == 0){
		[self protectedSetCurrentState:BTLSocketListening];
		
		if(manager != nil){
			[manager addListeningSocket:self];
		}
		
		return YES;
	}
	
	return NO;
}

- (BTLConnectionOrientedSocket*)accept
{
	 BTLTCPSocket* ret = nil;
	
	struct sockaddr_storage sockaddr;
	socklen_t length = sizeof(struct sockaddr_storage);
	int sd = accept(socketDescriptor, (struct sockaddr*) &sockaddr, &length);
	
	while(sd < 0 && (BTLGetError() == EINPROGRESS)){
		sd = accept(socketDescriptor, (struct sockaddr*) &sockaddr, &length);
	}
	
	if(sd > -1){
		BTLSocketAddress* address = [BTLSocketAddress addressWithSockaddrStruct:&sockaddr ofSize:length];
		if(delegate != nil && [delegate respondsToSelector:@selector(shouldConnectToAddress:sender:)]
		   && [delegate shouldConnectToAddress:address sender:self]== NO){
#ifdef WIN32
			closesocket(sd);
#else
			close(sd);
#endif
			return nil;
		}
		
		ret = [[BTLTCPSocket alloc] initSocketConnectedTo:address
									 withSocketDescriptor:sd
												 delegate:[self delegate]
											  handlerList:[self handlerListForAddress:address]
												  manager:[self manager]];
	}
	
	return ret;
}

#ifdef KEEP_UNDEFINED
#pragma mark Class Metods
#endif

+ (int)type
{
	return SOCK_STREAM;
}

+ (int)protocol
{
	return 6; // Protocol number for TCP as defined in /etc/protocols
}

#ifdef KEEP_UNDEFINED
#pragma mark Deallocation
#endif

- (void)dealloc
{	
	if(privateRemainingTimeout != nil){
		[privateRemainingTimeout release];
	}
	if(privateLastConnectionAttempt != nil){
		[privateLastConnectionAttempt release];
	}
	[super dealloc];
}

- (id)retain
{
	return [super retain];
}

- (void)release
{
	[super release];
}

@end
