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
#import "BTLSocket.h"
#import "BTLSocketHandler.h"

@interface BTLSocketHandlerList : NSObject {
	//! \brief The first handler in the list.
	BTLSocketHandler* protectedFirstHandler;
	
	//! \brief The last handler in the list.
	BTLSocketHandler* protectedLastHandler;
	
	//! \brief The socket which owns this list.
	BTLSocket* socket;
	
	//! YES if the socket can currently send data, NO otherwise.
	BOOL canWrite;
}

#ifdef KEEP_UNDEFINED
#pragma mark Connecting and Disconnectiong
#endif

- (void)connectionOpenedToAddress:(BTLSocketAddress*)anAddress;
- (void)connectionFailedToAddress:(BTLSocketAddress*)anAddress;
- (void)connectionClosedToAddress:(BTLSocketAddress*)anAddress;
- (void)connectionInterruptedToAddress:(BTLSocketAddress*)anAddress;
- (void)connectionClosedByRemoteAddress:(BTLSocketAddress*)anAddress;

#ifdef KEEP_UNDEFINED
#pragma mark Reading and Writing
#endif

- (void)readData:(BTLSocketBuffer*)someData fromAddress:(BTLSocketAddress*)anAddress;
- (BOOL)writeData:(BTLSocketBuffer*)someData toAddress:(BTLSocketAddress*)anAddress;

#ifdef KEEP_UNDEFINED
#pragma mark BTLSocketHandler Management
#endif

- (void)addHandlerToFront:(BTLSocketHandler*)aHandler;
- (void)addHandlerToEnd:(BTLSocketHandler*)aHandler;

- (void)removeHandler:(BTLSocketHandler*)aHandler;
- (void)removeAll;

#ifdef KEEP_UNDEFINED
#pragma mark Accessors
#endif

- (void)setSocket:(BTLSocket*)aSocket;
- (BTLSocket*)socket;

- (BOOL)canWrite;

@end
