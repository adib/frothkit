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

#import "BTLSocketIPV6Address.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <netdb.h>

#define IPV6_ADDR_LEN 40

//! The BTLSocketIPV6Address class implements accessors for IPv6 addresses as
//! well as a function for testing whether a string is an IPv6 address.

@implementation BTLSocketIPV6Address

#ifdef KEEP_UNDEFINED
#pragma mark Loading
#endif

+ (void)load
{
	[self registerWithSuperclass];
}

#ifdef KEEP_UNDEFINED
#pragma mark Equality Methods
#endif

- (BOOL)isEqualToSockaddrStruct:(struct sockaddr_storage*)aSockaddr
{
	if(aSockaddr == NULL){
		return NO;
	}
	
	if(aSockaddr->ss_family != sockaddr.ss_family){
		return NO;
	}
	
	if(((struct sockaddr_in6*) &sockaddr)->sin6_port = ((struct sockaddr_in6*) aSockaddr)->sin6_port){
		return NO;
	}
	
	int i;
	for(i = 0; i < sizeof(struct in6_addr); ++i){
		if(((struct sockaddr_in6*) &sockaddr)->sin6_addr.s6_addr[i] !=
		   ((struct sockaddr_in6*) aSockaddr)->sin6_addr.s6_addr[i]){
			return NO;
		}
	}
	
	return YES;
}

#ifdef KEEP_UNDEFINED
#pragma mark Accessors
#endif

- (BOOL)setHostname:(NSString*)aHostname error:(NSError**)anError
{
	BOOL ret = NO;
	
	if(aHostname != nil){
		[aHostname retain];
	}else{
		aHostname = [[NSString alloc] initWithCString:"0::0" encoding:NSUTF8StringEncoding];
	}
	
	size = sizeof(struct sockaddr_in6);
	
	memset(&sockaddr, 0, size);
	
	if([aHostname isEqualToString:@""] || [aHostname isEqualToString:@"0::0"]){
		sockaddr.ss_family = AF_INET6;
		struct in6_addr in6_any = IN6ADDR_ANY_INIT;
		((struct sockaddr_in6*) &sockaddr)->sin6_addr = in6_any;
		ret = YES;
	}else{
		if([aHostname isEqualToString:@"localhost"] || [aHostname isEqualToString:@"loopback"]){
			[aHostname release];
			aHostname = @"::1";
		}
		
		struct addrinfo* results;
		struct addrinfo hints;
		hints.ai_flags = 0;
		hints.ai_family = AF_INET6;
		hints.ai_socktype = 0;
		hints.ai_protocol = 0;
		hints.ai_addrlen = 0;
		hints.ai_addr = NULL;
		hints.ai_canonname = NULL;
		hints.ai_next = NULL;
		
		int error;
		if(!(error = getaddrinfo([aHostname cStringUsingEncoding:NSUTF8StringEncoding], NULL, &hints, &results))){
			sockaddr.ss_family = AF_INET6;
			memcpy(((struct sockaddr_in6*) &sockaddr)->sin6_addr.s6_addr,
				   ((struct sockaddr_in6*) results->ai_addr)->sin6_addr.s6_addr, sizeof(struct in6_addr));
			ret = YES;
		}else{
			if(anError != NULL){
				NSArray* keys = [NSArray arrayWithObjects:@"NSLocalizedDescriptionKey", nil];
				NSArray* objects = [NSArray arrayWithObjects:[NSString stringWithCString:gai_strerror(error)
																				encoding:NSUTF8StringEncoding], nil];
				NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
				*anError = [[[NSError alloc] initWithDomain:@"BTLSocketAddressErrorDomain" code:error
												   userInfo:userInfo] autorelease];
			}
		}
		
		freeaddrinfo(results);
	}
	
#ifdef HAS_SA_LEN
	((struct sockaddr*) &sockaddr)->sa_len = size;
#endif
	
	
	[aHostname release];
	return ret;
}

- (NSString*)address
{
	NSString* ret = nil;
	char dst[IPV6_ADDR_LEN];
	inet_ntop(AF_INET6, &(((struct sockaddr_in6*) &sockaddr)->sin6_addr), &dst, IPV6_ADDR_LEN);
	ret = [[NSString alloc] initWithCString:dst encoding:NSUTF8StringEncoding];
	return [ret autorelease];
}

- (NSString*)hostname
{
	NSString* ret = nil;
	char dst[NI_MAXHOST];
	if(!(getnameinfo(((const struct sockaddr*) &sockaddr), size, dst, NI_MAXHOST, NULL, 0, 0))){
		ret = [[NSString alloc] initWithCString:dst encoding:NSUTF8StringEncoding];
	}else{
		ret = [[NSString alloc] initWithCString:"" encoding:NSUTF8StringEncoding];
	}
	return [ret autorelease];
}

- (BOOL)setPort:(in_port_t)aPort error:(NSError**)anError
{
	((struct sockaddr_in6*) &sockaddr)->sin6_port = htons(aPort);
	return YES;
}

- (in_port_t)port
{
	return ntohs(((struct sockaddr_in6*) &sockaddr)->sin6_port);
}

- (NSString*)serviceForProtocol:(int)aProtocol
{
	int flags = 0;
	if(aProtocol == SOCK_DGRAM){
		flags |= NI_DGRAM;
	}
	
	NSString* ret = nil;
	char dst[NI_MAXSERV];
	if(!getnameinfo(((const struct sockaddr*) &sockaddr), size, NULL, 0, dst, NI_MAXSERV, flags)){
		ret = [[NSString alloc] initWithCString:dst encoding:NSUTF8StringEncoding];
	}else{
		ret = [[NSString alloc] initWithCString:"" encoding:NSUTF8StringEncoding];
	}
	return [ret autorelease];
}

#ifdef KEEP_UNDEFINED
#pragma mark Class Methods
#endif

+ (sa_family_t)family
{
	return AF_INET6;
}

@end

#ifdef KEEP_UNDEFINED
#pragma mark Testing
#endif

//! \returns YES if the string is in the correct format for an IPv6 address, but
//! not necessarily if it is a valid address, NO otherwise.

BOOL isIPv6Address(NSString* anAddress)
{
	BOOL ret = YES;
	
	NSArray* halves = [anAddress componentsSeparatedByString:@"%"];
	NSString* newAddress = [halves objectAtIndex:0];
	[halves release];
	[anAddress release];
	
	if([newAddress length] > IPV6_ADDR_LEN - 1){
		ret = NO;
	}
	
	if( ret == YES && [newAddress rangeOfString:@":"].location == NSNotFound){
		ret = NO;
	}
	
	return ret;
}