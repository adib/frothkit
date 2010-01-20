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
#import "BTLSocketBuffer.h"
#import "BTLSocketAddress.h"
@class BTLSocketHandlerList;

@interface BTLSocketHandler : NSObject {
	
	//! \brief The next handler in the linked list
	BTLSocketHandler* nextHandler;
	
	//! \brief The previous handler in the linked list
	//!
	//! The previous handler may be an instance of BTLSocket.
	id prevHandler;
	
	//! \brief The BTLSocketHandlerList which this BTLSocketHandler is a part of
	BTLSocketHandlerList* encapsulatingList;
}

#ifdef KEEP_UNDEFINED
#pragma mark Connecting and Disconnecting
#endif

- (void)connectionOpenedToAddress:(BTLSocketAddress*)anAddress;
- (void)finishedOpeningConnectionToAddress:(BTLSocketAddress*)anAddress;

- (void)closeConnectionToAddress:(BTLSocketAddress*)anAddress;
- (void)finishedClosingConnectionToAddress:(BTLSocketAddress*)anAddress;

- (void)connectionFailedToAddress:(BTLSocketAddress*)anAddress;
- (void)connectionInterruptedToAddress:(BTLSocketAddress*)anAddress;
- (void)connectionClosedByRemoteAddress:(BTLSocketAddress*)anAddress;


#ifdef KEEP_UNDEFINED
#pragma mark Reading and Writing
#endif

- (void)readData:(BTLSocketBuffer*)someData fromAddress:(BTLSocketAddress*)anAddress;
- (void)finishedReadingData:(BTLSocketBuffer*)someData fromAddress:(BTLSocketAddress*)anAddress;

- (BOOL)writeData:(BTLSocketBuffer*)someData toAddress:(BTLSocketAddress*)anAddress;
- (BOOL)finishedWritingData:(BTLSocketBuffer*)someData toAddress:(BTLSocketAddress*)anAddress;

#ifdef KEEP_UNDEFINED
#pragma mark Accessors
#endif

- (void)removeSelf;
- (void)removeAll;

- (void)setNextHandler:(BTLSocketHandler*)aManager;
- (void)setPrevHandler:(id)aManager;

- (BTLSocketHandler*)nextHandler;
- (id)prevHandler;

- (void)setEncapsulatingList:(BTLSocketHandlerList*)aList;
- (BTLSocketHandlerList*)encapsulatingList;

@end
