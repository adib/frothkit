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
#import <pthread.h>

#import "BTLSocket.h"
#import "BTLConnectionOrientedSocket.h"
#import "BTLSocketBuffer.h"
#import "BTLSocketAddress.h"

@interface BTLSocketManager : NSObject {
	//! \brief An array of sockets which are already connected.
	NSMutableArray* protectedConnectedSockets;
	
	//! \brief An array of sockets which are in the process of connecting.
	NSMutableArray* protectedConnectingSockets;
	
	//! \brief An array of sockets which are listening for incoming connections.
	NSMutableArray* protectedListeningSockets;
	
	//! \brief The highest numbered socket descritptor of connecting sockets.
	int privateHighestConnectedSocket;
	
	//! \brief A set of all of the sockets currently connected.
	fd_set privateConnectedSocketSet;
	
	//! \brief The highest numbered socket descritptor of listening sockets.
	int privateHighestListeningSocket;
	
	//! \brief A set of all of the sockets currently connected.
	fd_set privateListeningSocketSet;
	
	pthread_mutex_t connectedAddMutex;
	pthread_mutex_t connectedRemoveMutex;
	pthread_mutex_t connectingAddMutex;
	pthread_mutex_t connectingRemoveMutex;
	pthread_mutex_t listeningAddMutex;
	pthread_mutex_t listeningRemoveMutex;
}

#ifdef KEEP_UNDEFINED
#pragma mark Socket Management
#endif

- (void)addConnectedSocket:(BTLSocket*)aSocket;
- (void)removeConnectedSocket:(BTLSocket*)aSocket;

- (void)addListeningSocket:(BTLConnectionOrientedSocket*)aSocket;
- (void)removeListeningSocket:(BTLConnectionOrientedSocket*)aSocket;

- (void)addConnectingSocket:(BTLConnectionOrientedSocket*)aSocket;
- (void)removeConnectingSocket:(BTLConnectionOrientedSocket*)aSocket;

- (void)removeSocket:(BTLSocket*)aSocket;

- (void)select;

@end
