//
//  NetworkingTests.m
//  FrothKit
//
//  Created by Allan Phillips on 15/01/10.
//  Copyright 2010 Thinking Code Software Inc. All rights reserved.
//

#import "NetworkingTests.h"
#import "BTLTCPSocketTestDelegate.h"

#import <bits/socket.h>

#define STAssertTrue FRAssertTrue
#define STAssertFalse FRAssertFalse
#define STAssertEquals FRAssertEquals
#define STAssertNotNil FRAssertNotNil
#define STFail FRFail

BOOL m_initialized = FALSE;

@implementation NetworkingTests

- (NSArray*)tests {
	return [NSArray arrayWithObjects:@"test_TCPIPv4Socket", nil];
}

- (void)test_TCPIPv4Socket {
	NSLog(@"--starting tcpip4socket tests--");
	
	//becouse +load does not get called?
	//[BTLSocketAddress registerWithSuperclass];
	if(!m_initialized) {
	[BTLSocketIPV4Address registerWithSuperclass];
	[BTLSocketIPV6Address registerWithSuperclass];
	[BTLSocket registerWithSuperclass];
	[BTLUDPSocket registerWithSuperclass];
	[BTLTCPSocket registerWithSuperclass];
	
	[BTLSocketBuffer initialize];
		m_initialized = TRUE;
	}
	
	NSError* err;
	BTLSocketIPAddress* addr1 = [BTLSocketIPAddress addressWithHostname:@"localhost" port:0 family:AF_INET error:&err];
	if(!addr1) {
		FRFail([err localizedDescription]);
	}
	
	BTLSocketIPAddress* addr2 = [BTLSocketIPAddress addressWithHostname:@"127.0.0.1" port:0 family:AF_INET error:nil];
	BTLSocketIPAddress* addr3 = [BTLSocketIPAddress addressWithHostname:@"169.0.0.1" port:33345 family:AF_INET error:nil];
	
	//FRAssertNotNil(addr1, @"failed");
	//FRAssertNotNil(addr2, @"failed");
	
	NSLog(@"--got addrs for test--");
	
	[self testManagedTCPSocketWithSourceAddress:addr1 withDestinationAddress:addr2 badAddress:addr3];
	[self testUnmanagedTCPSocketWithSourceAddress:addr1 withDestinationAddress:addr2 badAddress:addr3];
	[self testUnmanagedDelegatelessTCPSocketWithSourceAddress:addr1 withDestinationAddress:addr2]; // Socket timeout does not apply to unmanaged, delegateless sockets.

	NSLog(@"test finished");
}

- (void)testManagedTCPSocketWithSourceAddress:(BTLSocketAddress*)addr1 withDestinationAddress:(BTLSocketAddress*)addr2 badAddress:(BTLSocketAddress*)badAddress
{	
	if(addr1 == nil || addr2 == nil){
		NSLog(@"___NO addr1 or addr2___");
		FRFail(@"No addr1 or addr2 for testMAnagedTCPSocket LINE");
		return;
	}
	
	BTLSocketManager* testManager = [BTLSocketManager new];
	
	BTLTCPSocketTestDelegate* testDelegate1 = [BTLTCPSocketTestDelegate new];
	BTLTCPSocketTestDelegate* testDelegate2 = [BTLTCPSocketTestDelegate new];
		
	BTLTCPSocket* sock1 = (BTLTCPSocket*) [BTLSocket socketWithAddressFamily:[addr1 family] type:SOCK_STREAM];
	
	//NSLog(@"Class of sock1:%@", NSStringFromClass(sock1));
	FRAssertNotNil(sock1, nil);
	STAssertTrue([sock1 bindToAddress:addr1], nil);	//failing here...
	
	[sock1 setDelegate:testDelegate1];
	[sock1 setManager:testManager];
	
	BTLTCPSocket* sock2 = (BTLTCPSocket*) [BTLSocket socketWithAddressFamily:[addr1 family] type:SOCK_STREAM];
	STAssertTrue([sock2 bindToAddress:addr2], nil);
	[sock2 setDelegate:testDelegate2];
	[sock2 setManager:testManager];
	
	STAssertFalse([sock1 canReadFromAddress:[sock1 localAddress]], nil);
	STAssertFalse([sock1 canWriteToAddress:[sock1 localAddress]], nil);
	STAssertFalse([sock1 canReadFromAddress:[sock1 remoteAddress]], nil);
	STAssertFalse([sock1 canWriteToAddress:[sock1 remoteAddress]], nil);
	STAssertFalse([sock2 canReadFromAddress:[sock2 localAddress]], nil);
	STAssertFalse([sock2 canWriteToAddress:[sock2 localAddress]], nil);
	STAssertFalse([sock2 canReadFromAddress:[sock2 remoteAddress]], nil);
	STAssertFalse([sock2 canWriteToAddress:[sock2 remoteAddress]], nil);
	
	STAssertTrue([sock2 listenWithBacklog:5], nil);
	
	[testDelegate1 setForbiddenAddress:[sock2 localAddress]];
	
	NSNumber* timeout = [[NSNumber alloc] initWithDouble:200.0];
	STAssertFalse([sock1 connectToAddress:[sock2 localAddress] withTimeout:timeout], nil);
	STAssertTrue([testDelegate1 connectionFailed], nil);
	STAssertFalse([testDelegate2 currentlyConnected], nil);
	[testDelegate1 setForbiddenAddress:nil];
	
	[sock1 connectToAddress:badAddress withTimeout:[NSNumber numberWithDouble:5.0]];
	while([testDelegate1 connectionFailed] != YES){
		[testManager select];
	}
	
	[sock1 connectToAddress:[sock2 localAddress] withTimeout:timeout];
	[testManager select];
	
	BTLTCPSocket* sock3 = (BTLTCPSocket*) [testDelegate2 lastSocket];
	
	while(sock3 == nil){
		[testManager select];
		sock3 = (BTLTCPSocket*) [testDelegate2 lastSocket];
	}
	[sock3 retain];
	
	[testManager select];
	
	while(![sock1 isConnected]){
		[testManager select];
		STAssertFalse([testDelegate1 connectionFailed], nil);
	}
	
	STAssertTrue([sock1 isConnected], nil);
	STAssertFalse([sock2 isConnected], nil);
	STAssertTrue([sock3 isConnected], nil);
	STAssertTrue([testDelegate1 currentlyConnected], nil);
	STAssertTrue([testDelegate2 currentlyConnected], nil);
	
	STAssertFalse([sock1 canReadFromAddress:[sock1 localAddress]], nil);
	STAssertFalse([sock1 canWriteToAddress:[sock1 localAddress]], nil);
	STAssertTrue([sock1 canReadFromAddress:[sock1 remoteAddress]], nil);
	STAssertTrue([sock1 canWriteToAddress:[sock1 remoteAddress]], nil);
	STAssertFalse([sock2 canReadFromAddress:[sock2 localAddress]], nil);
	STAssertFalse([sock2 canWriteToAddress:[sock2 localAddress]], nil);
	STAssertFalse([sock2 canReadFromAddress:[sock2 remoteAddress]], nil);
	STAssertFalse([sock2 canWriteToAddress:[sock2 remoteAddress]], nil);
	STAssertFalse([sock3 canReadFromAddress:[sock3 localAddress]], nil);
	STAssertFalse([sock3 canWriteToAddress:[sock3 localAddress]], nil);
	STAssertTrue([sock3 canReadFromAddress:[sock3 remoteAddress]], nil);
	STAssertTrue([sock3 canWriteToAddress:[sock3 remoteAddress]], nil);
	
	BTLSocketBuffer* data1 = [BTLSocketBuffer new];
	[data1 addData:"Test String" ofSize:12];
	[sock1 writeData:data1 toAddress:nil];
	
	[testManager select];
	
	STAssertEquals(testDelegate2, [sock3 delegate], nil);
	
	BTLSocketBuffer* testData = [testDelegate2 lastMessage];
	
	while(testData == nil){
		[testManager select];
		testData = [testDelegate2 lastMessage];
	}
	
	STAssertNotNil(testData, nil);
	
	if(strcmp([testData rawData], [data1 rawData]) != 0){
		STFail(@"First data not equal", nil);
	}
	
	[sock3 writeData:data1 toAddress:nil];
	[testManager select];
	
	testData = nil;
	testData = [testDelegate1 lastMessage];
	
	while(testData == nil){
		[testManager select];
		testData = [testDelegate1 lastMessage];
	}
	
	STAssertNotNil(testData, nil);
	
	if(strcmp([testData rawData], [data1 rawData]) != 0){
		STFail(@"Second data not equal");
	}
	
	srand(time(0));
	char buffer[3000];
	int i;
	for(i = 0; i < 3000; ++i){
		buffer[i] = rand() % 256; // Who cares about mod bias?
	}
	
	[data1 release];
	
	data1 = [BTLSocketBuffer new];
	[data1 addData:buffer ofSize:3000];
	[sock1 writeData:data1 toAddress:nil];
	
	[testManager select];
	testData = [testDelegate2 lastMessage];
	
	while(testData == nil){
		[testManager select];
		testData = [testDelegate2 lastMessage];
	}
	
	STAssertEquals([testData size], [data1 size], nil);
	
	const char* result = [testData rawData];
	for(i = 0; i < 3000; ++i){
		if(result[i] != buffer[i]){
			STFail(@"Char buffers not equal at iteration %d", i, nil);
			break;
		}
	}
	
	[sock1 closeConnectionToAddress:nil];
	STAssertFalse([testDelegate1 currentlyConnected], nil);
	[testManager select];
	STAssertTrue([testDelegate2 remoteDisconnected], nil);
	[sock3 connectionInterruptedToAddress:nil];
	STAssertFalse([testDelegate2 currentlyConnected], nil);
	
	[data1 release];
	[timeout release];
	[sock3 release];
	[sock2 release];
	[sock1 release];
	[testManager release];
	[testDelegate2 release];
	[testDelegate1 release];
}

- (void)testUnmanagedTCPSocketWithSourceAddress:(BTLSocketAddress*)addr1 withDestinationAddress:(BTLSocketAddress*)addr2 badAddress:(BTLSocketAddress*)badAddress
{
	if(addr1 == nil || addr2 == nil){
		FRFail(@"No addr1 or addr2 for testUnmangedManagedTCPSocket LINE");
		return;
	}
	
	BTLTCPSocketTestDelegate* testDelegate1 = [BTLTCPSocketTestDelegate new];
	BTLTCPSocketTestDelegate* testDelegate2 = [BTLTCPSocketTestDelegate new];
	
	BTLTCPSocket* sock1 = (BTLTCPSocket*) [BTLSocket socketWithAddressFamily:[addr1 family] type:SOCK_STREAM];
	STAssertTrue([sock1 bindToAddress:addr1], nil);
	[sock1 setDelegate:testDelegate1];
	
	BTLTCPSocket* sock2 = (BTLTCPSocket*) [BTLSocket socketWithAddressFamily:[addr1 family] type:SOCK_STREAM];
	STAssertTrue([sock2 bindToAddress:addr2], nil);
	
	STAssertFalse([sock1 canReadFromAddress:[sock1 localAddress]], nil);
	STAssertFalse([sock1 canWriteToAddress:[sock1 localAddress]], nil);
	STAssertFalse([sock1 canReadFromAddress:[sock1 remoteAddress]], nil);
	STAssertFalse([sock1 canWriteToAddress:[sock1 remoteAddress]], nil);
	STAssertFalse([sock2 canReadFromAddress:[sock2 localAddress]], nil);
	STAssertFalse([sock2 canWriteToAddress:[sock2 localAddress]], nil);
	STAssertFalse([sock2 canReadFromAddress:[sock2 remoteAddress]], nil);
	STAssertFalse([sock2 canWriteToAddress:[sock2 remoteAddress]], nil);
	
	STAssertTrue([sock2 listenWithBacklog:5], nil);
	[testDelegate1 setForbiddenAddress:[sock2 localAddress]];
	
	NSNumber* timeout = [[NSNumber alloc] initWithDouble:200.0];
	STAssertFalse([sock1 connectToAddress:[sock2 localAddress] withTimeout:timeout], nil);
	STAssertTrue([testDelegate1 connectionFailed], nil);
	STAssertFalse([testDelegate2 currentlyConnected], nil);
	[testDelegate1 setForbiddenAddress:nil];
	
	[sock1 connectToAddress:badAddress withTimeout:[NSNumber numberWithDouble:5.0]];
	while([testDelegate1 connectionFailed] != YES){
		[sock1 connectToAddress:nil withTimeout:nil];
	}
	
	[sock1 connectToAddress:[sock2 localAddress] withTimeout:timeout];
	BTLTCPSocket* sock3 = (BTLTCPSocket*) [sock2 accept];
	[sock1 connectToAddress:nil withTimeout:nil];
	
	while(sock3 == nil){
		sock3 = (BTLTCPSocket*) [sock2 accept];
	}
	
	[sock3 setDelegate:testDelegate2];
	if([[sock3 delegate] respondsToSelector:@selector(connectionOpenedToAddress:sender:)]){
		[[sock3 delegate] connectionOpenedToAddress:[sock3 remoteAddress] sender:sock3];
	}
	
	while(![sock1 isConnected]){
		[sock1 connectToAddress:nil withTimeout:nil];
	}
	
	STAssertTrue([sock1 isConnected], nil);
	STAssertFalse([sock2 isConnected], nil);
	STAssertTrue([sock3 isConnected], nil);
	STAssertTrue([testDelegate1 currentlyConnected], nil);
	STAssertTrue([testDelegate2 currentlyConnected], nil);
	
	STAssertFalse([sock1 canReadFromAddress:[sock1 localAddress]], nil);
	STAssertFalse([sock1 canWriteToAddress:[sock1 localAddress]], nil);
	STAssertTrue([sock1 canReadFromAddress:[sock1 remoteAddress]], nil);
	STAssertTrue([sock1 canWriteToAddress:[sock1 remoteAddress]], nil);
	STAssertFalse([sock2 canReadFromAddress:[sock2 localAddress]], nil);
	STAssertFalse([sock2 canWriteToAddress:[sock2 localAddress]], nil);
	STAssertFalse([sock2 canReadFromAddress:[sock2 remoteAddress]], nil);
	STAssertFalse([sock2 canWriteToAddress:[sock2 remoteAddress]], nil);
	STAssertFalse([sock3 canReadFromAddress:[sock3 localAddress]], nil);
	STAssertFalse([sock3 canWriteToAddress:[sock3 localAddress]], nil);
	STAssertTrue([sock3 canReadFromAddress:[sock3 remoteAddress]], nil);
	STAssertTrue([sock3 canWriteToAddress:[sock3 remoteAddress]], nil);
	
	BTLSocketBuffer* data1 = [BTLSocketBuffer new];
	[data1 addData:"Test String" ofSize:12];
	[sock1 writeData:data1 toAddress:nil];
	
	[sock3 read];
	
	STAssertEquals(testDelegate2, [sock3 delegate], nil);
	
	BTLSocketBuffer* testData = [testDelegate2 lastMessage];
	
	while(testData == nil){
		[sock3 read];
		testData = [testDelegate2 lastMessage];
	}
	
	STAssertNotNil(testData, nil);
	
	if(strcmp([testData rawData], [data1 rawData]) != 0){
		STFail(@"First data not equal", nil);
	}
	
	[sock3 writeData:data1 toAddress:nil];
	[sock1 read];
	
	testData = nil;
	testData = [testDelegate1 lastMessage];
	
	while(testData == nil){
		[sock1 read];
		testData = [testDelegate1 lastMessage];
	}
	
	STAssertNotNil(testData, nil);
	
	if(strcmp([testData rawData], [data1 rawData]) != 0){
		STFail(@"Second data not equal");
	}
	
	[sock1 closeConnectionToAddress:nil];
	STAssertFalse([testDelegate1 currentlyConnected], nil);
	while([testDelegate2 currentlyConnected]){
		[sock3 read];
	}
	STAssertTrue([testDelegate2 remoteDisconnected], nil);
	[sock3 connectionInterruptedToAddress:nil];
	STAssertFalse([testDelegate2 currentlyConnected], nil);
	
	[timeout release];
	[sock3 release];
	[sock2 release];
	[sock1 release];
	[testDelegate2 release];
	[testDelegate1 release];
}

- (void)testUnmanagedDelegatelessTCPSocketWithSourceAddress:(BTLSocketAddress*)addr1 withDestinationAddress:(BTLSocketAddress*)addr2
{
	if(addr1 == nil || addr2 == nil){
		FRFail(@"No addr1 or addr2 for testUnmangedManagedDelegatelessTCPSocket LINE");
		return;
	}
	
	BTLTCPSocket* sock1 = (BTLTCPSocket*) [BTLSocket socketWithAddressFamily:[addr1 family] type:SOCK_STREAM];
	STAssertTrue([sock1 bindToAddress:addr1], nil);
	
	BTLTCPSocket* sock2 = (BTLTCPSocket*) [BTLSocket socketWithAddressFamily:[addr1 family] type:SOCK_STREAM];
	STAssertTrue([sock2 bindToAddress:addr2], nil);
	
	STAssertFalse([sock1 canReadFromAddress:[sock1 localAddress]], nil);
	STAssertFalse([sock1 canWriteToAddress:[sock1 localAddress]], nil);
	STAssertFalse([sock1 canReadFromAddress:[sock1 remoteAddress]], nil);
	STAssertFalse([sock1 canWriteToAddress:[sock1 remoteAddress]], nil);
	STAssertFalse([sock2 canReadFromAddress:[sock2 localAddress]], nil);
	STAssertFalse([sock2 canWriteToAddress:[sock2 localAddress]], nil);
	STAssertFalse([sock2 canReadFromAddress:[sock2 remoteAddress]], nil);
	STAssertFalse([sock2 canWriteToAddress:[sock2 remoteAddress]], nil);
	
	STAssertTrue([sock2 listenWithBacklog:5], nil);
	
	NSNumber* timeout = [[NSNumber alloc] initWithDouble:200.0];
	
	[sock1 connectToAddress:[sock2 localAddress] withTimeout:timeout];
	BTLTCPSocket* sock3 = (BTLTCPSocket*) [sock2 accept];
	[sock1 connectToAddress:nil withTimeout:nil];
	
	while(sock3 == nil){
		sock3 = (BTLTCPSocket*) [sock2 accept];
	}
	
	while(![sock1 isConnected]){
		[sock1 connectToAddress:nil withTimeout:nil];
	}
	
	STAssertTrue([sock1 isConnected], nil);
	STAssertFalse([sock2 isConnected], nil);
	STAssertTrue([sock3 isConnected], nil);
	
	STAssertFalse([sock1 canReadFromAddress:[sock1 localAddress]], nil);
	STAssertFalse([sock1 canWriteToAddress:[sock1 localAddress]], nil);
	STAssertTrue([sock1 canReadFromAddress:[sock1 remoteAddress]], nil);
	STAssertTrue([sock1 canWriteToAddress:[sock1 remoteAddress]], nil);
	STAssertFalse([sock2 canReadFromAddress:[sock2 localAddress]], nil);
	STAssertFalse([sock2 canWriteToAddress:[sock2 localAddress]], nil);
	STAssertFalse([sock2 canReadFromAddress:[sock2 remoteAddress]], nil);
	STAssertFalse([sock2 canWriteToAddress:[sock2 remoteAddress]], nil);
	STAssertFalse([sock3 canReadFromAddress:[sock3 localAddress]], nil);
	STAssertFalse([sock3 canWriteToAddress:[sock3 localAddress]], nil);
	STAssertTrue([sock3 canReadFromAddress:[sock3 remoteAddress]], nil);
	STAssertTrue([sock3 canWriteToAddress:[sock3 remoteAddress]], nil);
	
	BTLSocketBuffer* data1 = [BTLSocketBuffer new];
	[data1 addData:"Test String" ofSize:12];
	[sock1 writeData:data1 toAddress:nil];
	
	BTLSocketBuffer* testData = [sock3 read];
	
	while(testData == nil){
		testData = [sock3 read];
	}
	
	STAssertNotNil(testData, nil);
	
	if(strcmp([testData rawData], [data1 rawData]) != 0){
		STFail(@"First data not equal", nil);
	}
	
	testData = nil;
	[sock3 writeData:data1 toAddress:nil];
	testData = [sock1 read];
	
	while(testData == nil){
		testData = [sock1 read];
	}
	
	STAssertNotNil(testData, nil);
	
	if(strcmp([testData rawData], [data1 rawData]) != 0){
		STFail(@"Second data not equal");
	}
	
	[sock1 closeConnectionToAddress:nil];
	[sock3 connectionInterruptedToAddress:nil];
	
	[data1 release];
	[timeout release];
	[sock3 release];
	[sock2 release];
	[sock1 release];
}


@end
