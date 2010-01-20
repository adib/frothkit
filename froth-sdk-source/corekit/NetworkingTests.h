//
//  NetworkingTests.h
//  FrothKit
//
//  Created by Allan Phillips on 15/01/10.
//  Copyright 2010 Thinking Code Software Inc. All rights reserved.
//

#import "FrothTestCase.h"
#import "Networking/BTLSockets.h"

@interface NetworkingTests : FrothTestCase {

}

//From BTTCPSocketTest.h
- (void)testManagedTCPSocketWithSourceAddress:(BTLSocketAddress*)addr1 withDestinationAddress:(BTLSocketAddress*)addr2 badAddress:(BTLSocketAddress*)badAddress;
- (void)testUnmanagedTCPSocketWithSourceAddress:(BTLSocketAddress*)addr1 withDestinationAddress:(BTLSocketAddress*)addr2 badAddress:(BTLSocketAddress*)badAddress;
- (void)testUnmanagedDelegatelessTCPSocketWithSourceAddress:(BTLSocketAddress*)addr1 withDestinationAddress:(BTLSocketAddress*)addr2;

@end
