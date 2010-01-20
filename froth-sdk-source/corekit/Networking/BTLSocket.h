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
#import "BTLSocketAddress.h"
#import "BTLSocketBuffer.h"

@class BTLSocketHandler;
@class BTLSocketHandlerList;
@class BTLSocketManager;

#ifdef WIN32
#import <Winsock.h>
#else
#import <sys/socket.h>
#import <fcntl.h>
#import <arpa/inet.h>
#endif

typedef enum
{
	BTLSocketDisconnected,
	BTLSocketConnecting,
	BTLSocketListening,
	BTLSocketConnected
} BTLSocketState;

@interface BTLSocket : NSObject {
	//! Holds the socket descriptor returned by the sockets API
	int socketDescriptor;
	
	//! The local address bound to the socket.
	BTLSocketAddress* localAddress;
	
	//! The remote address the socket is connected to.
	//!
	//! For connectionless sockets, this variable holds the last address read
	//! by the socket. To get an NSArray of all remote addresses that the socket
	//! has read from or written to, use remoteAddresses().
	BTLSocketAddress* remoteAddress;
	
	//! \brief The master BTLSocketHandlerList.
	//!
	//! When a connection is made, a handler list is created for the remote
	//! address by calling BTLHanderList::copyWithZone() on the master
	//! BTLHandlerList if it is not nil. Otherwise, a new BTLHandlerList will
	//! be created.
	BTLSocketHandlerList* masterHandlerList;
	
	//! The internal state of the socket.
	//!
	//! There should be no public accessors for this state. Instead, methods
	//! like BTLSocket::isConnected() return values based on the state.
	BTLSocketState protectedCurrentState;
	
	//! \brief A temporary buffer used when the socket is its own delegate.
	//!
	//! The socket's read() method will ultimately end up calling the delegate's
	//! readData:fromAddress:sender:() method. However, if the socket's delegate
	//! is itself, then the data that was read is put into privateBuffer, which
	//! is autoreleased, and the read method returns the privateBuffer.
	BTLSocketBuffer* privateBuffer;
	
	//! \brief The address family of the socket.
	//!
	//! Only addresses of the same family can be bound to the socket.
	//!
	//! \sa BTLSocket::initWithAddressFamily:type:potocol:
	sa_family_t addressFamily;
	
	//! \brief the sockets type.
	//!
	// \sa BTLSocket::initWithAddressFamily:type:potocol:
	int type;
	
	//! \brief The transport layer protocol.
	//!
	//! \sa BTLSocket::initWithAddressFamily:type:potocol:
	int protocol;
	
	//! \brief the size of the recieving buffer.
	int recieveBufferSize;
	
	//! \brief the size of the sending buffer.
	int sendBufferSize;
	
#ifdef WIN32
	//! Whether or not the socket is in blocking mode. Win32 only.
	BOOL blocking;
#endif
	
	//! The socket's delegate. Defaults to the socket itself.
	id delegate;
	
	//! The socket's manager.
	BTLSocketManager* manager;
}

#ifdef KEEP_UNDEFINED
#pragma mark Initializers
#endif

+ (id)socketWithAddressFamily:(sa_family_t)aFamily type:(int)aType;
+ (id)socketWithAddressFamily:(sa_family_t)aFamily type:(int)aType protocol:(int)aProtocol;
- (id)initWithAddressFamily:(sa_family_t)aFamily type:(int)aTLProtocol protocol:(int)aProtocol;

#ifdef KEEP_UNDEFINED
#pragma mark Connecting and Disconnecting
#endif

- (BOOL)bindToAddress:(BTLSocketAddress*)anAddress;

- (BOOL)connectToAddress:(BTLSocketAddress*)anAddress withTimeout:(NSNumber*)timeout;

- (BOOL)closeConnectionToAddress:(BTLSocketAddress*)anAddress;
- (void)finishedClosingConnectionToAddress:(BTLSocketAddress*)anAddress;

- (void)connectionInterruptedToAddress:(BTLSocketAddress*)anAddress;

#ifdef KEEP_UNDEFINED
#pragma mark Reading and Writing
#endif

- (BTLSocketBuffer*)read;
- (void)readData:(BTLSocketBuffer*)someData fromAddress:(BTLSocketAddress*)anAddress;
- (BOOL)writeData:(BTLSocketBuffer*)someData toAddress:(BTLSocketAddress*)anAddress;
- (BOOL)finishedWritingData:(BTLSocketBuffer*)someData toAddress:(BTLSocketAddress*)anAddress;

- (BOOL)canReadFromAddress:(BTLSocketAddress*)anAddress;
- (BOOL)canWriteToAddress:(BTLSocketAddress*)anAddress;

#ifdef KEEP_UNDEFINED
#pragma mark Blocking Methods
#endif

- (BOOL)blocking;
- (BOOL)setBlocking:(BOOL)shouldBlock;

#ifdef KEEP_UNDEFINED
#pragma mark BTLSocketHandlerList Management
#endif

- (void)addHandlerToFront:(BTLSocketHandler*)aHandler forAddress:(BTLSocketAddress*)anAddress;
- (void)addHandlerToEnd:(BTLSocketHandler*)aHandler forAddress:(BTLSocketAddress*)anAddress;

- (void)setHandlerList:(BTLSocketHandlerList*)aList forAddress:(BTLSocketAddress*)anAddress;
- (BTLSocketHandlerList*)handlerListForAddress:(BTLSocketAddress*)anAddress;
- (void)resetHandlerListForAddress:(BTLSocketAddress*)anAddress;

#ifdef KEEP_UNDEFINED
#pragma mark Master BTLSocketHandlerList Management
#endif

- (void)addHandlerToFrontOfMasterList:(BTLSocketHandler*)aHandler;
- (void)addHandlerToEndOfMasterList:(BTLSocketHandler*)aHandler;

- (void)setMasterHandlerList:(BTLSocketHandlerList*)aList;
- (BTLSocketHandlerList*)masterHandlerList;
- (void)removeMasterHandlerList;

#ifdef KEEP_UNDEFINED
#pragma mark State
#endif

- (BOOL)isListening;
- (BOOL)isConnecting;
- (BOOL)isConnected;

#ifdef KEEP_UNDEFINED
#pragma mark Accessors
#endif

- (int)socketDescriptor;
- (BOOL)isConnectionOriented;

- (BTLSocketAddress*)localAddress;
- (BTLSocketAddress*)remoteAddress;
- (NSArray*)remoteAddresses;

- (sa_family_t)addressFamily;
- (int)type;
- (int)protocol;

- (int)recieveBufferSize;
- (BOOL)setRecieveBufferSize:(int)aSize;
- (int)sendBufferSize;
- (BOOL)setSendBufferSize:(int)aSize;

- (void)setDelegate:(id)aDelegate;
- (id)delegate;

- (void)setManager:(BTLSocketManager*)aManager;
- (BTLSocketManager*)manager;

#ifdef KEEP_UNDEFINED
#pragma mark Class Methods
#endif

+ (void)registerWithSuperclass;
+ (id)classForType:(int)aType protocol:(int)aProtocol;
+ (int)protocol;
+ (int)type;

@end

@protocol BTLSocketDelegate

#ifdef KEEP_UNDEFINED
#pragma mark Delegate Methods
#endif

//! \brief Called to determine whether to accept or reject a connection.
//
//! This method may be used to reject connections from specific addresses. It is
//! Called before a socket connects to a remote address. For connection-oriented
//! sockets, this method will not be called after it returns YES. For all other
//! sockets, this method will not be called for a certain address after it
//! returns YES for that address. For both kinds of sockets, the method may be
//! called multiple times for the same, previously-rejected address. Rejecting
//! an address is not perminant.
//!
//! If the delegate does not implement this method, the socket will assume a
//! return value of YES.
//!
//! \return YES to accept a connection, NO to reject a connection.

- (BOOL)shouldConnectToAddress:(BTLSocketAddress*)anAddress sender:(id)sender;

//! \brief Called when the socket successfully makes a new connection.
//
//! In connection-oriented sockets, this method will be called at most once.
//! Connection-oriented sockets are invalidated when disconnected, and can only
//! make one connection at a time. In all other sockets, the method will be
//! called whenever the socket either sends data to, or recieves data from an
//! address which it has not previously sent data to or recieved data from. The
//! method will not be called twice for the same address, so it can not be used,
//! for example, to identify addresses which you have sent data to but not
//! recieved data from.
//!
//! This method is called after the connection is made, but before any data has
//! been read from or written to the socket, except any data sent or recieved by
//! the socket's BTLSocketHandlerList, which is notified that the connection
//! is opened before the delegate is. Delegates for connection-oriented sockets
//! may examine the address and call the BTLSocket::closeConnectionToAddress:()
//! method on the socket to reject a connection, keeping in mind that a closed
//! connection-oriented socket can not be re-opened.

- (void)connectionOpenedToAddress:(BTLSocketAddress*)anAddress sender:(id)sender;

//! \brief Called when the socket fails to make a new connection.
//
//! This method is called only for connection-oriented sockets. It is called
//! when the socket attempts to connect to or accept a connection from a remote
//! address and fails. The socket is still valid and may be used to attempt to
//! reconnect or connect to a different address.

- (void)connectionFailedToAddress:(BTLSocketAddress*)anAddress sender:(id)sender;

//! \brief Called to determine whether to close a connection.
//
//! This method is called by the socket whenever 
//! BTLSocket::closeConnectionToAddress:() is called on the socket.
//!
//! If the delegate does not implement this method, the socket will assume a
//! return value of YES.
//!
//! \returns YES to close a connection, NO to keep it open.

- (BOOL)shouldCloseConnectionToAddress:(BTLSocketAddress*)anAddress sender:(id)sender;

//! \brief Called when the socket closes a connection.
//
//! This method is called after the connection is closed. for
//! connection-oriented sockets the socket is invalid and may not be used for
//! further connections. For all other sockets the BTLSocketHandlerList is
//! removed for that address and further communication with that address will
//! generate a call to shouldConnectToAddress:sender:().

- (void)connectionClosedToAddress:(BTLSocketAddress*)anAddress sender:(id)sender;

//! \brief Called when a remote socket causes the connection to close.
//
//! For TCP connections, this method signifies that the remote socket has closed
//! its end of the connection. The local socket can still send data over the
//! connection, but will not recieve any more data from the remote socket. It is
//! common for this method to call BTLSocket::closeConnectionToAddress:()
//! unless the socket needs to remain open to send more data.

- (void)connectionClosedByRemoteAddress:(BTLSocketAddress*)anAddress sender:(id)sender;

//! \brief called when a connection is ungracefully disconnected.
//
//! This method is called only for connection-oriented sockets. It is called
//! when the socket detects that the connection has been broken. The socket is
//! invalidated before the method is called. This method should close the socket
//! using BTLSocket::closeConnectionToAddress:() to unbind the socket from its
//! local address.

- (void)connectionInterruptedToAddress:(BTLSocketAddress*)anAddress sender:(id)sender;

//! \brief Called when the socket recieves data.
//
//! This method is called when data is recieved and passed through the
//! socket's BTLSocketHandlerList. For connection-oriented sockets, anAddress
//! will be equal to the socket's remoteAddress by the
//! BTLSocketAddress::isEqual:() method. In all other sockets, anAddress will
//! contain the address which sent the data.
//!
//! The someData BTLSocketBuffer may be modified by the BTLSocketHandlerList
//! before this method is called. BTLSocketHandler classes may pass a
//! BTLSocketBuffer which contains data that has already been read. Unless the
//! data already read by the BTLSocketHandler is needed, the
//! BTLSocketBuffer::remainingRawData() should be called to get the raw data.

- (void)readData:(BTLSocketBuffer*)someData fromAddress:(BTLSocketAddress*)anAddress sender:(BTLSocket*)sender;

@end

#ifdef KEEP_UNDEFINED
#pragma mark Blocking Functions
#endif

BOOL setNonBlocking(int socketDescriptor);
BOOL setBlocking(int socketDescriptor);
