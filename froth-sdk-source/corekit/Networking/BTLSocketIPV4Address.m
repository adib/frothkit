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

#import "BTLSocketIPV4Address.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <netdb.h>

#define IPV4_ADDR_LEN 16

//! The BTLSocketIPV6Address class implements accessors for IPv4 addresses as
//! well as a function for testing whether a string is an IPv4 address.

@implementation BTLSocketIPV4Address

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
	
	if(((struct sockaddr_in*) &sockaddr)->sin_port != ((struct sockaddr_in*) aSockaddr)->sin_port){
		return NO;
	}
	
	if(((struct sockaddr_in*) &sockaddr)->sin_addr.s_addr != ((struct sockaddr_in*) aSockaddr)->sin_addr.s_addr){
		return NO;
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
		aHostname = [[NSString alloc] initWithCString:"0.0.0.0" encoding:NSUTF8StringEncoding];
	}
	
	size = sizeof(struct sockaddr_in);
	
	memset(&sockaddr, 0, size);
	
	if([aHostname isEqualToString:@""] || [aHostname isEqualToString:@"0.0.0.0"]){
		sockaddr.ss_family = AF_INET;
		((struct sockaddr_in*) &sockaddr)->sin_addr.s_addr = INADDR_ANY;
		ret = YES;
	}else{
		if([aHostname isEqualToString:@"localhost"] || [aHostname isEqualToString:@"loopback"]){
			[aHostname release];
			aHostname = @"127.0.0.1";
		}
		
		struct addrinfo* results;
		struct addrinfo hints;
		hints.ai_flags = 0;
		hints.ai_family = AF_INET;
		hints.ai_socktype = 0;
		hints.ai_protocol = 0;
		hints.ai_addrlen = 0;
		hints.ai_addr = NULL;
		hints.ai_canonname = NULL;
		hints.ai_next = NULL;
		
		int error;
		if(!(error = getaddrinfo([aHostname cStringUsingEncoding:NSUTF8StringEncoding], NULL, &hints, &results))){
			sockaddr.ss_family = results->ai_family;
			((struct sockaddr_in*) &sockaddr)->sin_addr.s_addr =
				((struct sockaddr_in*) results->ai_addr)->sin_addr.s_addr;
			ret = YES;
		}else{
			if(anError != NULL){
				NSArray* keys = [NSArray arrayWithObjects:@"NSLocalizedDescriptionKey", nil];
				NSArray* objects = [NSArray arrayWithObjects:[NSString stringWithCString:gai_strerror(error)
																				encoding:NSUTF8StringEncoding], nil];
				NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
				*anError = [[[NSError alloc] initWithDomain:@"BTLSocketAddressErrorDomain"
													   code:error userInfo:userInfo] autorelease];
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
	char dst[IPV4_ADDR_LEN];
	inet_ntop(AF_INET, &(((struct sockaddr_in*) &sockaddr)->sin_addr), &dst, IPV4_ADDR_LEN);
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
	((struct sockaddr_in*) &sockaddr)->sin_port = htons(aPort);
	return YES;
}

- (in_port_t)port
{
	return ntohs(((struct sockaddr_in*) &sockaddr)->sin_port);
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
	return AF_INET;
}

@end

#ifdef KEEP_UNDEFINED
#pragma mark Testing
#endif

//! \returns YES if the string is in the correct format for an IPv4 address, but
//! not necessarily if it is a valid address, NO otherwise.

BOOL isIPv4Address(NSString* anAddress)
{
	BOOL ret = YES;
	
	if([anAddress length] > IPV4_ADDR_LEN - 1){
		ret = NO;
	}
	
	NSArray* octets = nil;
	if(ret == YES){
		octets = [anAddress componentsSeparatedByString:@"."];
		if([octets count] != 4){
			ret = NO;
		}
	}
	
	if(ret == YES){
		int i;
		for(i = 0; i < 4; ++i){
			NSString* temp = [octets objectAtIndex:i];
			if([temp length] < 1 || [temp length] > 3){
				ret = NO;
			}
			
			if(ret == YES){
				int j;
				for(j = 0; j < [temp length]; ++j){
					char c = [temp characterAtIndex:j];
					if(c < '0' || c > '9'){
						ret = NO;
					}
				}
			}
			
			if(ret == YES){
				int v = [temp intValue];
				if(v < 0 || v > 255){
					ret = NO;
				}
			}
		}
	}
	
	if(octets != nil){
		[octets release];
	}
	
	return ret;
}