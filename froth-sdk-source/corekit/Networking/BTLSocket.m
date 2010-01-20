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

#import "BTLSocket.h"
#import "BTLSocket+Protected.h"
#import "BTLSocketHandlerList.h"
#import "BTLConnectionOrientedSocket.h"

static NSMutableDictionary* BTLSocketSubclassDict;

//! The BTLSocket class sends and recieves data to and from remote
//! sockets.
//!
//! This class contains methods for connecting and disconnecting to and from
//! remote sockets, reading and writing data to and from remote sockets, and
//! controlling the blocking behavior of the local socket. Many of these methods
//! are abstract, and are implemented by subclasses. Since Objective-C does not
//! contain any functionalty for defining abstract methods, the methods which
//! are absctract are identified in the documentation. Subclasses should
//! should implement these abstract methods.
//!
//! This class also contains methods for handling BTLSocketList instances for
//! the socket. These methods are all abstract, but are all implemented by
//! BTLConnectionLessSocket and BTLConnectionOriented socket. This class also
//! contains methods for handling the master BTLSocketList instance, which are
//! all concrete methods.
//!
//! N.B. BTLSocket's copyWithZone:() method does not make an exact copy of the
//! socket. It makes a new socket with the same address family, type, protocol
//! and master handler list, but with a different socket descriptor. However,
//! the isEqual:() method tests or equality by socket descriptor. As such, it
//! can not be used as the key in an NSDictionary object, or any other object
//! that requires copyWithZone:() to return an exact copy.

@implementation BTLSocket

#ifdef KEEP_UNDEFINED
#pragma mark Loading
#endif

//! \brief initializes the Winsock2 library for Windows
+ (void)load
{
#ifdef WIN32
	WSADATA w;
	int error = WSAStartup (0x0202, &w);
	
	if(error){
		NSLog(@"Could not start up Winsock due to error %d.", error);
		exit(0);
	}
	
	if(w.wVersion != 0x0202){
		WSACleanup();
		NSLog(@"Unable to load proper Winsock version.");
		exit(0);
	}
#endif
}

#ifdef KEEP_UNDEFINED
#pragma mark Initializers
#endif

//! \brief Returns a socket of the specified type using the specified address
//! without specifying a protocol.
//! \sa BTLSocket::initWithAddressFamily:type:potocol:

+ (id)socketWithAddressFamily:(sa_family_t)aFamily type:(int)aType
{
	return [self socketWithAddressFamily:aFamily type:aType protocol:0];
}

//! \brief Returns a socket of the specified type using the specified address
//!  and protocol 
//!
//! \sa initWithAddressFamily:type:potocol:

+ (id)socketWithAddressFamily:(sa_family_t)aFamily type:(int)aType protocol:(int)aProtocol
{
	id class = [self classForType:aType protocol:aProtocol];
	if(class != nil){
		if(aProtocol == 0){
			aProtocol = [class protocol];
		}
		return [[class alloc] initWithAddressFamily:aFamily type:aType protocol:aProtocol];
	}
	return nil;
}

//! \brief Initializes a non-blocking socket which is its own delegate.
//!
//! This is the ultimate init method for the BTLSocket class. All other init
//! methods of the class should call [self init] instead of [super init].

- (id)init
{
	[super init];
	
	unsigned int optlen = sizeof(int);
	getsockopt(socketDescriptor, SOL_SOCKET, SO_RCVBUF, &recieveBufferSize, &optlen);
	getsockopt(socketDescriptor, SOL_SOCKET, SO_SNDBUF, &sendBufferSize, &optlen);
	
#ifdef WIN32
	blocking = YES;
#endif
	
	[self setBlocking:NO];
	[self protectedSetCurrentState:BTLSocketDisconnected];
	
	[self setDelegate:self];
	
	return self;
}

//! \brief Creates a socket of the specified transport layer protocol (e.g. TCP,
//! UDP), using the specified address family over the specified network layer
//! protocol.
//!
//! Values for the address family are defined on UNIX and UNIX-like systems in
//! sys/socket.h, and on Windows in winsock2.h. Only addresses of the same
//! family can be bound to the socket, so if the address to which the socket
//! will be bound is known in advance, the addressFamily parameter should be
//! filled in using BTLSocketAddress::family(). The BTLSockets framework ships
//! with support for AF_INET (IPv4) and AF_INET6 (IPv6) values, but more address
//! families can be added by subclassing BTLSocketAddress.
//!
//! Values for the type  are also defined in sys/socket.h and winsock2.h. The
//! BTLSockets framework ships with support for SOCK_STREAM and SOCK_DGRAM
//! types, but more transport layer protocols can be added by subclassing
//! BTLSocket.
//!
//! Values for the protocol are defined in /etc/protocols on UNIX and UNIX-like
//! systems, and in winssock2.h on Windows. Unlike the other parameters,
//! the BTLSockets framework supports all transport layer protocols
//! availiable on the host system.
//!
//! N.B. Not all systems support the values listed in their headers.
//! For exmaple, even though winsock2.h lists AF_UNIX, Windows does not support
//! UNIX sockets. On UNIX and UNIX like systems, a list of supproted address
//! families can often be found in the manual page for socket(2). A list of
//! supported address families for Windows can be found in the Winsock
//! reference, currently (April 2008) located at
//! http://msdn2.microsoft.com/en-us/library/ms740506(VS.85).aspx
//!
//! N.B. If implementing a subclass of BTLSocket which does not use BSD sockets
//! or Winsock, take special care to make sure that the values used for address
//! family and type are unique with regards to the values for address family and
//! type defined in these libraries.

- (id)initWithAddressFamily:(sa_family_t)aFamily type:(int)aType protocol:(int)aProtocol
{
	id ret = nil;
	
	socketDescriptor = socket(aFamily, aType, aProtocol);
	if(socketDescriptor > -1){
		addressFamily = aFamily;
		type = aType;
		protocol = aProtocol;
		ret = [self init]; // Must be after call to socket().
	}
	
	return ret;
}

#ifdef KEEP_UNDEFINED
#pragma mark Copyting
#endif

- (id)copyWithZone:(NSZone*)zone
{
	BTLSocket* ret = [BTLSocket socketWithAddressFamily:[self addressFamily] type:[self type]];
	[ret setMasterHandlerList:masterHandlerList];
	return ret;
}

#ifdef KEEP_UNDEFINED
#pragma mark Connecting and Disconnecting
#endif

//! \brief Binds the socket to the specified address.
//!
//! Binding the socket to the local address. Binding a socket to an address
//! associates the socket with that address, so it can send and recieve data.
//!
//! Sockets bound to an address are unbound by
//! BTLSocket::closeConnectionToAddress:().
//!
//! \returns YES if the connection succeeded, NO if it did not.

- (BOOL)bindToAddress:(BTLSocketAddress*)anAddress
{
	int ret = bind(socketDescriptor, (struct sockaddr*) [anAddress sockaddr], [anAddress size]);
	if(ret == 0){
		struct sockaddr_storage temp;
		socklen_t tempLength = sizeof(struct sockaddr_storage);
		getsockname(socketDescriptor, (struct sockaddr*) &temp, &tempLength);
		[self protectedSetLocalAddress:[BTLSocketAddress addressWithSockaddrStruct:&temp ofSize:tempLength]];
	}
	return ret == 0;
}

//! \brief Connects the socket to the specified remote address.
//!
//! This method calls BTLSocketDelegate::shouldConnectToAddress:sender:() to
//! determine whether or not to make the connection. If that method returns NO,
//! This method will terminate before a connection is attempted. If the delegate
//! does not implement that method, the connection will be attempted as if the
//! returned YES.
//!
//! The timeout parameter controls how long the socket will wait for the
//! connection to succeed. The value is expressed as the number of seconds to
//! to wait. Fractional seconds are allowed. The timeout mechanism is not
//! precise: the socket may wait for slightly longer than the timeout value for
//! the connection to succeed. If a socket has failed to connect after the
//! timeout period, BTLSocketDelegate::connectionFailedToAddress:sender:() will
//! be called if the delegate implements that method.
//!
//! For connectionless sockets, this method creates a new BTLSocketHandlerList
//! for the specified address if there is not an existing BTLSocketHandlerList
//! for that address. Connectionless sockets ignore the timeout parameter.
//!
//! \returns YES if the connection succeeded, NO if it did not.

- (BOOL)connectToAddress:(BTLSocketAddress*)anAddress withTimeout:(NSNumber*)timeout
{
	return NO;
}

//! \brief Closes the connection to the remote address.
//!
//! For connection-oriented sockets, the anAddress parameter is ignored. After
//! this method is called, connection-oriented sockets are unbound from their
//! local addresses, and are invalidated.
//!
//! For all other sockets, this method will remove the BTLSocketHandlerList
//! for the specified address if it exists.
//!
//! This method calls
//! BTLSocketDelegate::shouldCloseConnectionToAddress:sender:() to determine
//! whether or not to close the connection.
//!
//! \returns YES if the operation succeeded, NO if it did not.

- (BOOL)closeConnectionToAddress:(BTLSocketAddress*)anAddress
{
	if(delegate != nil && [delegate respondsToSelector:@selector(shouldCloseConnectionToAddress:sender:)]
	   && [delegate shouldCloseConnectionToAddress:anAddress sender:self] == NO){
		return NO;
	}
	
	[[self handlerListForAddress:anAddress] connectionClosedToAddress:anAddress];
	return YES;
}

//! \brief closes the remote connection.
//!
//! This method is called after the BTLSocketHandlerList for the connection
//! has processed the BTLSocketHandlerList::ConnectionClosedToAddress() event.
//! It should not be called manually.
//!
//! This method is abstract and should be implemented by a subclass.

- (void)finishedClosingConnectionToAddress:(BTLSocketAddress*)anAddress
{
	// This method intentionally left blank.
}

//! \brief causes the connection to be forcibly closed.
//!
//! This method should be called when a timeout is connected to the remote
//! address.

- (void)connectionInterruptedToAddress:(BTLSocketAddress*)anAddress
{
	[[self handlerListForAddress:anAddress] connectionInterruptedToAddress:anAddress];
	[self finishedClosingConnectionToAddress:anAddress];
}

#ifdef KEEP_UNDEFINED
#pragma mark Reading and Writing
#endif

//! \brief Reads data from a remote address and passes it to the delegate
//!
//! This method will read as much data as is currently in the socket and pass it
//! through the BTLSocketHandlerList and then to the delegate. The method will
//! read as much data as possible from the socket before sending the data to the
//! BTLSocketHandlerList. If it encounters data from a different address, it
//! will forward the data it currenty has and continue reading data until there
//! is none left.

- (BTLSocketBuffer*)read
{
	return nil;
}

//! \brief Passes the specified data through the BTLSocketHandlerList for the
//! specified address.
//!
//! This method can be used to simulate incoming data from the specified
//! address.
//!
//! This method is abstract and should be implemented by a subclass.

- (void)readData:(BTLSocketBuffer*)someData fromAddress:(BTLSocketAddress*)anAddress
{
	// This method intentionally left blank.
}

//! \brief Writes data to a remote address.
//!
//! This method passes the data through the BTLSocketHandlerList for the
//! specified address. If such a list does not exist, calls
//! finishedWritingData:toAddress:().
//!
//! This method is abstract and should be implemented by a subclass.

- (BOOL)writeData:(BTLSocketBuffer*)someData toAddress:(BTLSocketAddress*)anAddress
{
	return NO;
}

//! \brief Writes data to a remote address.
//!
//! This method is called after the data to be written has been processed by
//! the BTLSocketHandlerList for the specified address. It should not be
//! called manually.
//!
//! This method is abstract and should be implemented by a subclass.

- (BOOL)finishedWritingData:(BTLSocketBuffer*)someData toAddress:(BTLSocketAddress*)anAddress
{
	return NO;
}

//! \brief Checks if the socket is readable.
//!
//! A readable socket may not have any data to read, but may safely have its
//! read() method called.
//!
//! \returns YES if the socket is readable, NO otherwise.

- (BOOL)canReadFromAddress:(BTLSocketAddress*)anAddress
{
	return NO;
}

//! \brief Checks if the socket is writable.
//!
//! A writable socket may safely have its writeData:toAddress:() method called.
//!
//! \returns YES if the socket is writable, NO otherwise.

- (BOOL)canWriteToAddress:(BTLSocketAddress*)anAddress
{
	return NO;
}

#ifdef KEEP_UNDEFINED
#pragma mark Blocking Methods
#endif

//! \brief Checks if the socket is set to blocking or non-blocking mode.
//!
//! By default, the BTLSockets framework uses non-blocking sockets. The
//! BTLSocketManager class expects the sockets to be non-blocking. However,
//! non-managed sockets can be used in blocking mode.

- (BOOL)blocking
{
#ifdef WIN32
	return blocking;
#else
	int opts = fcntl(socketDescriptor, F_GETFL, 0);
	if (opts < 0) {
		return NO;
	}
	
	return (opts & O_NONBLOCK) == 0;
#endif
}

//! \brief Sets the blocking mode for the socket.
//!
//! Passing YES as the shouldBlock parameter will put the socket into blocking
//! mode. Passing NO will put it in non-blocking mode.
//!
//! \sa blocking
//!
//! \returns YES if the operation succeeded, NO if it failed.

- (BOOL)setBlocking:(BOOL)shouldBlock
{
	BOOL ret = false;
	if(shouldBlock == YES){
		ret = setBlocking(socketDescriptor);
#ifdef WIN32
		if(ret == YES){
			blocking = YES;
		}
#endif
	}else{
		ret = setNonBlocking(socketDescriptor);
#ifdef WIN32
		if(ret == YES){
			blocking = NO;
		}
#endif
	}
	return ret;
}

#ifdef KEEP_UNDEFINED
#pragma mark BTLSocketHandlerList Management
#endif

//! \brief Adds the specified BTLSocketHandler to the front of the
//! BTLSocketHandlerList for the specified address.
//!
//! This method does nothing if the socket is not currently connected to the
//! specified address.
//!
//! This method is abstract and should be implemented by a subclass.

- (void)addHandlerToFront:(BTLSocketHandler*)aHandler forAddress:(BTLSocketAddress*)anAddress
{
	// This method intentionally left blank.
}

//! \brief Adds the specified BTLSocketHandler to the end of the
//! BTLSocketHandlerList for the specified address.
//!
//! This method does nothing if the socket is not currently connected to the
//! specified address.
//!
//! This method is abstract and should be implemented by a subclass.

- (void)addHandlerToEnd:(BTLSocketHandler*)aHandler forAddress:(BTLSocketAddress*)anAddress
{
	// This method intentionally left blank.
}

//! \brief Sets the BTLHanderList for the specified address.
//!
//! This method does nothing if the socket is not currently connected to the
//! specified address.
//!
//! This method is abstract and should be implemented by a subclass.

- (void)setHandlerList:(BTLSocketHandlerList*)aList forAddress:(BTLSocketAddress*)anAddress
{
	// This method intentionally left blank.
}


//! \returns the BTLHandlerList for the specified address, or nil if the socket
//! is not connected to the specified address or the specified address is nil.

- (BTLSocketHandlerList*)handlerListForAddress:(BTLSocketAddress*)anAddress
{
	return nil;
}

//! \brief Resets the BTLSocketHandlerList for the specified address to the
//! master BTLSocketHandlerList.
//!
//! This method does nothing if the socket is not currently connected to the
//! specified address.
//!
//! This method is abstract and should be implemented by a subclass.

- (void)resetHandlerListForAddress:(BTLSocketAddress*)anAddress
{
	// This method intentionally left blank.
}

#ifdef KEEP_UNDEFINED
#pragma mark Master BTLSocketHandlerList Management
#endif

//! \brief adds the specified BTLSocketHandler to the front of the master
//! BTLSocketHandlerList.
//!
//! Note that this method only adds the handler to the master
//! BTLSocketHandlerList. Currently active BTLSocketHandlerList objects will not
//! be affected, but newly-created BTLSocketHandlerList objects will.

- (void)addHandlerToFrontOfMasterList:(BTLSocketHandler*)aHandler
{
	if([self masterHandlerList] == nil){
		BTLSocketHandlerList* newMasterList = [BTLSocketHandlerList new];
		[self setMasterHandlerList:newMasterList];
		[newMasterList release];
	}
	[[self masterHandlerList] addHandlerToFront:aHandler];
}

//! \brief adds the specified BTLSocketHandler to the front of the master
//! BTLSocketHandlerList.
//!
//! Note that this method only adds the handler to the master
//! BTLSocketHandlerList. Currently active BTLSocketHandlerList objects will not
//! be affected, but newly-created BTLSocketHandlerList objects will.

- (void)addHandlerToEndOfMasterList:(BTLSocketHandler*)aHandler
{
	if([self masterHandlerList] == nil){
		BTLSocketHandlerList* newMasterList = [BTLSocketHandlerList new];
		[self setMasterHandlerList:newMasterList];
		[newMasterList release];
	}
	[[self masterHandlerList] addHandlerToFront:aHandler];
}

//! \brief Releases the current master BTLHandlerList and makes aList the new
//! master BTLHandlerList.

- (void)setMasterHandlerList:(BTLSocketHandlerList*)aList
{
	if(aList == nil || masterHandlerList == aList){
		return;
	}
	
	[masterHandlerList release];
	masterHandlerList = [aList copy];
	
	[masterHandlerList setSocket:self];
}

//! \returns the master BTLSocketHandlerList.

- (BTLSocketHandlerList*)masterHandlerList
{
	return masterHandlerList;
}

//! \brief Releases the master BTLSocketHandlerList and sets it to nil.

- (void)removeMasterHandlerList
{
	[self setMasterHandlerList:nil];
}

#ifdef KEEP_UNDEFINED
#pragma mark Delegate Methods
#endif

- (BOOL)shouldConnectToAddress:(BTLSocketAddress*)anAddress sender:(id)sender
{
	return YES;
}

- (BOOL)shouldCloseConnectionToAddress:(BTLSocketAddress*)anAddress sender:(id)sender
{
	return YES;
}

- (void)readData:(BTLSocketBuffer*)someData fromAddress:(BTLSocketAddress*)anAddress sender:(BTLSocket*)sender
{
	privateBuffer = someData;
}

#ifdef KEEP_UNDEFINED
#pragma mark State
#endif

//! \returns YES if the socket is listening for incoming connections, NO
//! otherwise.

- (BOOL)isListening
{
	return [self protectedCurrentState] == BTLSocketListening;
}

//! \return YES of the socket is connecting to a remote address, NO otherwise.

- (BOOL)isConnecting
{
	return [self protectedCurrentState] == BTLSocketConnecting;
}

//! \return YES of the socket is connected to one or more remote sockets, NO
//! otherwise.

- (BOOL)isConnected
{
	return [self protectedCurrentState] == BTLSocketConnected;
}

#ifdef KEEP_UNDEFINED
#pragma mark Accessors
#endif

//! \returns The BSD/Winsock socket descriptor for the socket.

- (int)socketDescriptor
{
	return socketDescriptor;
}

//! \returns YES if the socket is connection-oriented, NO otherwise.

- (BOOL)isConnectionOriented
{
	if([[self class] isSubclassOfClass:[BTLConnectionOrientedSocket class]]){
		return YES;
	}else{
		return NO;
	}
}

//! \returns the BTLSocketAddress bound to this socket.

- (BTLSocketAddress*)localAddress
{
	return localAddress;
}

- (BTLSocketAddress*)remoteAddress
{
	return remoteAddress;
}

//! \returns an NSArray of all remote addresses the socket is currently
//! connected to.
- (NSArray*)remoteAddresses
{
	return nil;
}

//! Only addresses of the same family can be bound to the socket.
//!
//! \returns the address family of the socket.
- (sa_family_t)addressFamily
{
	return addressFamily;
}

//! \returns the transport layer protocol of the socket.
- (int)type
{
	return type;
}

//! \returns the network layer protocol of the socket.
- (int)protocol
{
	return protocol;
}

//! \returns the size of the recieve buffer.

- (int)recieveBufferSize
{
	return recieveBufferSize;
}

//! \brief Set the size of the recieve buffer.

- (BOOL)setRecieveBufferSize:(int)aSize
{
	unsigned int optlen = sizeof(int);
	BOOL ret = (setsockopt(socketDescriptor, SOL_SOCKET, SO_RCVBUF, &aSize, optlen) == 0);
	if(ret == YES){
		recieveBufferSize = aSize;
	}
	
	return ret;
}

//! \returns the size of the send buffer.

- (int)sendBufferSize
{
	return sendBufferSize;
}

//! \brief Set the size of the send buffer.

- (BOOL)setSendBufferSize:(int)aSize
{
	unsigned int optlen = sizeof(int);
	BOOL ret = (setsockopt(socketDescriptor, SOL_SOCKET, SO_SNDBUF, &aSize, optlen) == 0);
	if(ret == YES){
		sendBufferSize = aSize;
	}
	
	return ret;
}

//! \brief Sets the socket's delegate.

- (void)setDelegate:(id)aDelegate
{	
	delegate = aDelegate;
}

//! \returns the socket's delegate.

- (id)delegate
{
	return delegate;
}

//! \brief Sets the socket's manager.

- (void)setManager:(BTLSocketManager*)aManager
{
	// Avoid a retain loop.
	manager = aManager;
}

//! \returns the socket's manager.

- (BTLSocketManager*)manager
{
	return manager;
}

#ifdef KEEP_UNDEFINED
#pragma mark Equality Methods
#endif

//! \returns YES if the two socket objects have the same socket descriptor, NO
//! otherwise.

- (BOOL)isEqual:(id)anObject
{
	if(anObject == nil){
		return NO;
	}
	
	if(anObject == self){
		return YES;
	}
	
	if([anObject isKindOfClass:[self class]]){
		return socketDescriptor == [anObject socketDescriptor];
	}
	
	return NO;
}

#ifdef KEEP_UNDEFINED
#pragma mark Class Methods
#endif

//! \brief registers a specific type (e.g. SOCK_STREAM, SOCK_DGRAM)/protocol 
//! (e.g. TCP/UDP) pair with a specific subclass of BTLSocket.
//!
//! This method should be called from the subclass's load method.
//!
//! \sa initWithAddressFamily:type:potocol:

+ (void)registerWithSuperclass
{
	if(objc_getClass("NSMutableDictionary") == nil){
		[self performSelector:@selector(registerWithSuperclass)
				   withObject:nil
				   afterDelay:0.5];
	}else{		
		if(BTLSocketSubclassDict == nil){
			BTLSocketSubclassDict = [[NSMutableDictionary alloc] initWithCapacity:4];
		}
		
		NSString* typeRep = [[NSString alloc] initWithFormat:@"%d", [self type]];
		
		NSMutableDictionary* typeDictionary = [BTLSocketSubclassDict objectForKey:typeRep];
		if(typeDictionary == nil){
			typeDictionary = [[NSMutableDictionary alloc] initWithCapacity:1];
			[BTLSocketSubclassDict setObject:typeDictionary forKey:typeRep];
		}
		[typeDictionary release];
		
		NSString* protocolRep = [[NSString alloc] initWithFormat:@"%d", [self protocol]];
		[typeDictionary setObject:[self class] forKey:protocolRep];
		
		[protocolRep release];
		[typeRep release];
	}
}

//! \sa registerProtocolWithSuperclass
//!
//! \returns the subclass associated with the type/protocol pair.
//!
////! \sa initWithAddressFamily:type:potocol:

+ (id)classForType:(int)aType protocol:(int)aProtocol;
{
	if(BTLSocketSubclassDict == nil){
		return nil;
	}
	
	NSString* typeRep = [[NSString alloc] initWithFormat:@"%d", aType];
	NSMutableDictionary* typeDictionary = [BTLSocketSubclassDict objectForKey:typeRep];
	[typeRep release];
	
	id class = nil;
	
	if(typeDictionary != nil || [typeDictionary count] < 0){
		
		// BSD sockets are designed so that each kind of socket can support
		// multiple protocols. A protocol of 0 will be replaced by the system
		// with the correct protocol. In the case that multiple protocols exist
		// for a single socket type, it is not possible to choose a replacement.
		//
		// The one exception is SOCK_STREAM and SOCK_DGRAM, which some
		// documentation specifies should use TCP and UDP respectively, and a
		// lot of existing code relies on this.
		
		if([typeDictionary count] > 1 && aProtocol == 0){
			if(aType == SOCK_STREAM){
				aProtocol = 6; // Protocol number for TCP as defined in /etc/protocols
				NSString* protocolRep = [[NSString alloc] initWithFormat:@"%d", aProtocol];
				class = [typeDictionary objectForKey:protocolRep];
				[protocolRep release];
			}else if(aType == SOCK_DGRAM){
				aProtocol = 17; // Protocol number for UDP as defined in /etc/protocols
				NSString* protocolRep = [[NSString alloc] initWithFormat:@"%d", aProtocol];
				class = [typeDictionary objectForKey:protocolRep];
				[protocolRep release];
			}else{
				class = nil;
			}
		} if(aProtocol == 0){
			class = [[typeDictionary objectEnumerator] nextObject];
		}else{
			NSString* protocolRep = [[NSString alloc] initWithFormat:@"%d", aProtocol];
			class = [typeDictionary objectForKey:protocolRep];
			[protocolRep release];
		}
	}
		
	if(class != nil && [class isSubclassOfClass:[self class]]){
		return class;
	}
	
	return nil;
}

//! \returns the transport later protocol implemented by this subclass.

+ (int)protocol
{
	return -1;
}

+ (int)type
{
	return -1;
}

#ifdef KEEP_UNDEFINED
#pragma mark Deallocation
#endif

- (void)dealloc
{
	if(localAddress != nil){
		[localAddress release];
	}
	
	if(remoteAddress != nil){
		[remoteAddress release];
	}
	
	if(masterHandlerList != nil){
		[masterHandlerList release];
	}
	
	[super dealloc];
}

- (id)retain
{
	return [super retain];
}

@end

@implementation BTLSocket (Protected)

#ifdef KEEP_UNDEFINED
#pragma mark Protected BTLSocketHandlerList Management
#endif

- (void)protectedCreateNewHandlerListForAddress:(BTLSocketAddress*)anAddress
{
	if([self handlerListForAddress:anAddress] != nil){
		return;
	}
	
	BTLSocketHandlerList* newList;
	
	if([self masterHandlerList] == nil){
		newList = [BTLSocketHandlerList new];
	}else{
		newList = [[self masterHandlerList] copy];
	}
	
	[newList setSocket:self];
	
	[self protectedAddHandlerList:newList forAddress:anAddress];
	[newList release];
}

//! This method is abstract and should be implemented by a subclass.

- (void)protectedAddHandlerList:(BTLSocketHandlerList*)aList forAddress:(BTLSocketAddress*)anAddress
{
	// This method intentionally left blank.
}

//! This method is abstract and should be implemented by a subclass.

- (void)protectedRemoveHandlerListForAddress:(BTLSocketAddress*)anAddress
{
	// This method intentionally left blank.
}

#ifdef KEEP_UNDEFINED
#pragma mark Protected Accessors
#endif

//! \brief Sets the local address, which the socket is bound to.

- (void)protectedSetLocalAddress:(BTLSocketAddress*)anAddress
{
	[anAddress retain];
	[localAddress release];
	localAddress = anAddress;
}

- (void)protectedSetRemoteAddress:(BTLSocketAddress*)anAddress
{
	[anAddress retain];
	[remoteAddress release];
	remoteAddress = anAddress;
}

//! \brief Sets the current socket's state.
//!
//! Subclasses should call this method during their connection and disconnection
//! processes. This method is an implementation detail. Class state information
//! is not exposed to the user in any way.

- (void)protectedSetCurrentState:(BTLSocketState)theState
{
	protectedCurrentState = theState;
}

//! \return the socket's current state.

- (BTLSocketState)protectedCurrentState
{
	return protectedCurrentState;
}

@end

#ifdef KEEP_UNDEFINED
#pragma mark Blocking Functions
#endif

//! \brief sets the specifiied socket descriptor socket as non-blocking.

BOOL setNonBlocking(int socketDescriptor)
{
#ifdef WIN32
	ULONG nonBlock = 1;
	if (ioctlsocket(socketDescriptor, FIONBIO, &nonBlock) == SOCKET_ERROR)
    {
    	return NO;
    }
#else
	int opts = fcntl(socketDescriptor, F_GETFL, 0);
	if (opts < 0) {
		return NO;
	}
	
	opts = (opts | O_NONBLOCK);
	if (fcntl(socketDescriptor,F_SETFL,opts) < 0) {
		return NO;
	}
#endif
	return YES;
}

//! \brief sets the specifiied socket descriptor socket as blocking.

BOOL setBlocking(int socketDescriptor)
{
#ifdef WIN32
	ULONG block = 0;
	if (ioctlsocket(socketDescriptor, FIONBIO, &block) == SOCKET_ERROR)
    {
    	return NO;
    }
#else
	int opts = fcntl(socketDescriptor, F_GETFL, 0);
	if (opts < 0) {
		return NO;
	}
	
	if((opts & O_NONBLOCK) != 0){
		opts = (opts ^ O_NONBLOCK);
	}
	
	if (fcntl(socketDescriptor, F_SETFL, opts) < 0) {
		return NO;
	}
#endif
	return YES;
}