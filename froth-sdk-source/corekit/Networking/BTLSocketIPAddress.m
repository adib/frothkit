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

#import "BTLSocketIPAddress.h"

//! The BTLSocketIPAddress class adds abstract accessor methods common to both
//! IPv4 and IPv6 addresses.

@implementation BTLSocketIPAddress

#ifdef KEEP_UNDEFINED
#pragma mark Initializers
#endif

//! \brief Creates a new IPv4 BTLSocketAddress with the specified address and
//! port.
//! 
//! \sa addressWithHostname:port:family:error:

+ (id)addressWithHostname:(NSString*)aHostname port:(in_port_t)aPort error:(NSError**)anError;
{
	return [self addressWithHostname:aHostname port:aPort family:AF_INET error:anError];
}

//! \brief Creates a new BTLSocketAddress of the soecified family with the
//! specified address and port.
//!
//! The error parameter, if non-nil is filled in with any error occuring during
//! the process.
//!
//! To create an address to bind to a local socket with the value INADDR_ANY,
//! pass @"0.0.0.0", @"", or nil as the hostname.
//!
//! \sa BTLSocket::initWithAddressFamily:type:potocol:

+ (id)addressWithHostname:(NSString*)aHostname port:(in_port_t)aPort family:(sa_family_t)aFamily
					error:(NSError**)anError;
{	
	id ret = nil;
		
	id class = [self classForFamily:aFamily];
	if(class != nil){
		ret = [[class alloc] initWithHostname:aHostname port:aPort error:anError];
	}else if(anError != NULL){
		NSArray* keys = [NSArray arrayWithObjects:@"NSLocalizedDescriptionKey", nil];
		NSArray* objects = [NSArray arrayWithObjects:@"No class found for specified address family.", nil];
		NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
		*anError = [[[NSError alloc] initWithDomain:@"BTLSocketAddressErrorDomain" code:0 userInfo:userInfo]
			autorelease];
	}

	return ret;
}

//! \brief Creates a new BTLSocketAddress of the soecified family with the
//! specified address and port.
//!
//! The error parameter, if non-nil is filled in with any error occuring during
//! the process.
//!
//! \sa BTLSocket::initWithAddressFamily:type:potocol:

- (id)initWithHostname:(NSString*)aHostname port:(in_port_t)aPort error:(NSError**)anError
{
	id ret = nil;
	self = [super init];
	
	if([self setHostname:aHostname error:anError] == YES){
		if([self setPort:aPort error:anError] == YES){
			ret = self;
		}
	}
	
	return ret;
}

#ifdef KEEP_UNDEFINED
#pragma mark Accessors
#endif

//! \brief Sets the address's hostname. Both IP addresses and hostnames are
//! allowed.

- (BOOL)setHostname:(NSString*)aHostname error:(NSError**)anError
{
	return NO;
}

//! \returns the IP address.

- (NSString*)address
{
	return nil;
}

//! returns the hostname.

- (NSString*)hostname
{
	return nil;
}

//! \brief Sets the port.

- (BOOL)setPort:(in_port_t)aPort error:(NSError**)anError
{
	return NO;
}

//! \returns the port.

- (in_port_t)port
{
	return 0;
}

//! \returns the service name for the specified protocol for this kind of
//! IP address.

- (NSString*)serviceForProtocol:(int)aProtocol
{
	return nil;
}

@end
