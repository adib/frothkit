//
//  NSString+Crypto.m
//  FrothKit
//
//  Created by Allan Phillips on 11/01/10.
//  Copyright 2010 Thinking Code Software Inc. All rights reserved.
//

#import "NSString+Crypto.h"
#import "NSData+Utilities.h"

#include <openssl/sha.h>
#include <openssl/hmac.h>
#include "base64.h"

@implementation NSString (Crypto)

- (NSString*)sha1HmacWithSecret:(NSString*)secret {
	char md[64]; /* longest known is SHA512 */
	size_t mdl;
	
	const char* sec = [secret UTF8String];
	const char* str = [self UTF8String];
	
	HMAC(EVP_sha1(), sec, strlen(sec), str, strlen(str), md, &mdl);
	
	NSData* hmac = [[NSData alloc] initWithBytes:(void*)md length:mdl];
	NSString* hmacstr = [hmac base64Encoding];
	[hmac release];
	
	return hmacstr;
}

- (NSString*)sha256HmacWithSecret:(NSString*)secret {
	char md[64]; /* longest known is SHA512 */
	size_t mdl;
	
	const char* sec = [secret UTF8String];
	const char* str = [self UTF8String];
	
	HMAC(EVP_sha256(), sec, strlen(sec), str, strlen(str), md, &mdl);
	
	NSData* hmac = [[NSData alloc] initWithBytes:(void*)md length:mdl];
	NSString* hmacstr = [hmac base64Encoding];
	[hmac release];
	
	return hmacstr;
}

- (NSString*)base64Encoding {
	return [[self dataUsingEncoding:NSUTF8StringEncoding] base64Encoding];
}

@end
