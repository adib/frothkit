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

#import "BTLSocketHandlerList.h"
#import "BTLSocketHandlerList+Protected.h"

//! The BTLSocketHandlerList class is a list of BTLSocketHandlers which
//! maintains a reference to the socket it is connected to.

@implementation BTLSocketHandlerList

#ifdef KEEP_UNDEFINED
#pragma mark Initialization
#endif

- (id)init
{
	self = [super init];
	canWrite = NO;
	return self;
}

#ifdef KEEP_UNDEFINED
#pragma mark Copying
#endif

- (id)copyWithZone:(NSZone*)zone
{
	BTLSocketHandlerList* ret = [BTLSocketHandlerList new];
	BTLSocketHandler* enumerator = [self protectedFirstHandler];
	
	while(enumerator != nil){
		[ret addHandlerToEnd:enumerator];
		enumerator = [enumerator nextHandler];
	}
	
	return ret;
}

#ifdef KEEP_UNDEFINED
#pragma mark Connecting and Disconnectiong
#endif

//! \brief Called by the socket when a connection is opened to another socket.
//!
//! If the list has any handlers, it calls
//! BTLSocketHandler::connectionOpenedToAddress:() on the first handler,
//! otherwise it calls BTLSocketDelegate::connectionOpenedToAddress:sender:() on
//! the delegate.

- (void)connectionOpenedToAddress:(BTLSocketAddress*)anAddress
{
	canWrite = YES;
	if([self protectedFirstHandler] != nil){
		[[self protectedFirstHandler] connectionOpenedToAddress:anAddress];
	}else if([[self socket] delegate] != nil
			 && [[[self socket] delegate] respondsToSelector:@selector(connectionOpenedToAddress:sender:)]){
		[[[self socket] delegate] connectionOpenedToAddress:anAddress sender:[self socket]];
	}
}

//! \brief Called by the socket when a connection is closed to another socket.
//!
//! If the list has any handlers, it calls
//! BTLSocketHandler::connectionClosedToAddress:() on the last handler,
//! otherwise it calls BTLSocketDelegate::connectionClosedToAddress:sender:()
//! on the delegate.

- (void)connectionClosedToAddress:(BTLSocketAddress*)anAddress
{
	canWrite = NO;
	
	if([[self socket] delegate] != nil
	   && [[[self socket] delegate] respondsToSelector:@selector(connectionClosedToAddress:sender:)]){
		[[[self socket] delegate] connectionClosedToAddress:anAddress sender:[self socket]];
	}
	
	if([self protectedLastHandler] != nil){
		[[self protectedLastHandler] closeConnectionToAddress:anAddress];
	}else if([self socket] != nil){
		[[self socket] finishedClosingConnectionToAddress:anAddress];
	}
}

//! \brief Called by the socket when it fails to connect to another socket.
//!
//! If the list has any handlers, it calls
//! BTLSocketHandler::connectionFailedToAddress:() on all of them,
//! otherwise it calls BTLSocketDelegate::connectionFailedToAddress:sender:()
//! on the delegate.

- (void)connectionFailedToAddress:(BTLSocketAddress*)anAddress
{
	canWrite = NO;
	
	if([self socket] != nil && [[self socket] delegate] != nil
	   && [[[self socket] delegate] respondsToSelector:@selector(connectionFailedToAddress:sender:)]){
		[[[self socket] delegate] connectionFailedToAddress:anAddress sender:[self socket]];
	}
	
	if([self protectedLastHandler] != nil){
		id currentHandler = [self protectedLastHandler];
		while(currentHandler != [self socket]){
			[currentHandler connectionFailedToAddress:anAddress];
			currentHandler = [currentHandler prevHandler];
		}
	}
}

//! \brief Called by the socket when the connection is interrupted.
//!
//! If the list has any handlers, it calls
//! BTLSocketHandler::connectionInterruptedToAddress:() on all of them,
//! otherwise it calls
//! BTLSocketDelegate::connectionInterruptedToAddress:sender:() on the delegate.

- (void)connectionInterruptedToAddress:(BTLSocketAddress*)anAddress
{
	canWrite = NO;
	
	if([self socket] != nil && [[self socket] delegate] != nil
	   && [[[self socket] delegate] respondsToSelector:@selector(connectionInterruptedToAddress:sender:)]){
		[[[self socket] delegate] connectionInterruptedToAddress:anAddress sender:[self socket]];
	}
	
	if([self protectedLastHandler] != nil){
		id currentHandler = [self protectedLastHandler];
		while(currentHandler != [self socket]){
			[currentHandler connectionInterruptedToAddress:anAddress];
			currentHandler = [currentHandler prevHandler];
		}
	}
}

//! \brief Called by the socket when the connection is closed by the other
//! socket.
//!
//! If the list has any handlers, it calls
//! BTLSocketHandler::connectionClosedByRemoteAddress:() on all of them,
//! otherwise it calls
//! BTLSocketDelegate::connectionClosedByRemoteAddress:sender:() on the
//! delegate.

- (void)connectionClosedByRemoteAddress:(BTLSocketAddress*)anAddress
{	
	if([self socket] != nil && [[self socket] delegate] != nil
	   && [[[self socket] delegate] respondsToSelector:@selector(connectionClosedByRemoteAddress:sender:)]){
		[[[self socket] delegate] connectionClosedByRemoteAddress:anAddress sender:[self socket]];
	}
	
	if([self protectedLastHandler] != nil){
		id currentHandler = [self protectedLastHandler];
		while(currentHandler != [self socket]){
			[currentHandler connectionClosedByRemoteAddress:anAddress];
			currentHandler = [currentHandler prevHandler];
		}
	}
}

#ifdef KEEP_UNDEFINED
#pragma mark Reading and Writing
#endif

//! \brief Called by the socket when it has read data from the remote socket.
//!
//! If the list has any handlers, it calls
//! BTLSocketHandler::readData:fromAddress:() on the first handler, otherwise it
//! calls BTLSocketDelegate::readData:fromAddress:sender:() on the delegate.

- (void)readData:(BTLSocketBuffer*)someData fromAddress:(BTLSocketAddress*)anAddress
{
	int64_t position = [someData position];
	[someData rewind];
	if([self protectedFirstHandler] == nil
	   && [[[self socket] delegate] respondsToSelector:@selector(readData:fromAddress:sender:)]){
		[[[self socket] delegate] readData:someData fromAddress:anAddress sender:[self socket]];
	}else{
		[[self protectedFirstHandler] readData:someData fromAddress:anAddress];
	}
	[someData setPosition:position];
}

//! \brief Called by the socket when it has data to write to the remote socket.
//!
//! If the list has any handlers, it calls
//! BTLSocketHandler::writeData:toAddress:() on the first handler, otherwise it
//! calls BTLSocketDelegate::writeData:toAddress:sender:() on the delegate.

- (BOOL)writeData:(BTLSocketBuffer*)someData toAddress:(BTLSocketAddress*)anAddress
{
	if([self canWrite]){
		int64_t position = [someData position];
		[someData rewind];
		
		BOOL ret;
		if([self protectedLastHandler] == nil){
			ret = [[self socket] finishedWritingData:someData toAddress:anAddress];
		}else{
			ret = [[self protectedLastHandler] writeData:someData toAddress:anAddress];
		}
		[someData setPosition:position];
		
		return ret;
	}
	
	return NO;
}

#ifdef KEEP_UNDEFINED
#pragma mark BTLSocketHandler management
#endif

//! \brief Adds a handler to the front of the list.

- (void)addHandlerToFront:(BTLSocketHandler*)aHandler
{
	if(aHandler == [self protectedFirstHandler] || aHandler == nil){
		return;
	}
	
	BTLSocketHandler* copiedHandler = [aHandler copy];
	
	if([self protectedFirstHandler] == nil){
		[self protectedSetFirstHandler:copiedHandler];
		[self protectedSetLastHandler:copiedHandler];
	}else{
		BTLSocketHandler* oldHandler = [self protectedFirstHandler];
		[self protectedSetFirstHandler:copiedHandler];
		[[self protectedFirstHandler] setNextHandler:oldHandler];
		[oldHandler setPrevHandler:[self protectedFirstHandler]];
	}
	[[self protectedFirstHandler] setPrevHandler:[self socket]];
	[[self protectedFirstHandler] setEncapsulatingList:self];
}

//! \brief Adds a handler to the end of the list.

- (void)addHandlerToEnd:(BTLSocketHandler*)aHandler
{
	if(aHandler == [self protectedLastHandler] || aHandler == nil){
		return;
	}
	
	if([self protectedFirstHandler] == nil){
		[self addHandlerToFront:aHandler];
		return;
	}
	
	BTLSocketHandler* oldHandler = [self protectedLastHandler];
	[self protectedSetLastHandler:[aHandler copy]];
	
	[oldHandler setPrevHandler:[self protectedLastHandler]];
	[[self protectedLastHandler] setNextHandler:oldHandler];
	[[self protectedLastHandler] setEncapsulatingList:self];
}

//! \brief Removes a handler if it is at the front or end of the list.
//!
//! This method should not be called manually. It is called by
//! BTLSocketHandler::removeSelf().

- (void)removeHandler:(BTLSocketHandler*)aHandler
{
	if(aHandler == [self protectedFirstHandler]){
		[self protectedSetFirstHandler:[aHandler nextHandler]];
	}
	
	if(aHandler == [self protectedLastHandler]){
		[self protectedSetLastHandler:[aHandler prevHandler]];
	}
}

//! \brief removes all of the handlers in the list.

- (void)removeAll
{
	if([self protectedFirstHandler] != nil){
		[[self protectedFirstHandler] removeAll];
	}
}

#ifdef KEEP_UNDEFINED
#pragma mark Accessors
#endif

- (void)setSocket:(BTLSocket*)aSocket
{
	// Avoid a retain loop.
	socket = aSocket;
}

- (BTLSocket*)socket
{
	return socket;
}

- (BOOL)canWrite
{
	return canWrite;
}

#ifdef KEEP_UNDEFINED
#pragma mark Deallocation
#endif

- (void)dealloc
{
	[self removeAll];
	
	[super dealloc];
}

@end

@implementation BTLSocketHandlerList (Protected)

#ifdef KEEP_UNDEFINED
#pragma mark Protected Accessors
#endif

- (BTLSocketHandler*)protectedFirstHandler
{
	return protectedFirstHandler;
}

- (void)protectedSetFirstHandler:(BTLSocketHandler*)aHandler
{
	protectedFirstHandler = aHandler;
}

- (BTLSocketHandler*)protectedLastHandler
{
	return protectedLastHandler;
}

- (void)protectedSetLastHandler:(BTLSocketHandler*)aHandler
{
	protectedLastHandler = aHandler;
}

@end
