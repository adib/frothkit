//
//  WebMutableRequest.m
//  FrothKit
//
//  Created by Allan Phillips on 19/01/10.
//  Copyright 2010 Thinking Code Software Inc. All rights reserved.
//

#import "WebMutableRequest.h"
#import "Froth+Exceptions.h"

@implementation WebMutableRequest

NSDictionary* cookiesFromHeaders(NSDictionary* headers) {
	NSMutableDictionary* cookiesDictionary = [[NSMutableDictionary alloc] initWithCapacity:20];
	NSString* cookiesStr = [headers valueForKey:@"Cookie"];
	if(cookiesStr) {
		NSArray* keyValues = [cookiesStr componentsSeparatedByString:@"; "];
		for(NSString* kv in keyValues) {
			NSArray* parts = [kv componentsSeparatedByString:@"="];
			NSString* key = [parts objectAtIndex:0];
			NSString* value;
			if(parts.count > 2) {
				value = [[parts subarrayWithRange:NSMakeRange(1, parts.count-1)] componentsJoinedByString:@"="];
			} else {
				value = [parts objectAtIndex:1];
			}
			
			if([[cookiesDictionary allKeys] containsObject:key]) {
				id obj = [cookiesDictionary objectForKey:key];
				if([obj isKindOfClass:[NSMutableArray class]]) {
					[(NSMutableArray*)obj addObject:value];
				} else {
					NSMutableArray* multi = [[NSMutableArray alloc] initWithCapacity:5];
					[multi addObject:obj];
					[multi addObject:value];
					
					[cookiesDictionary setObject:multi forKey:key];
					
					[multi release];
				}
			} else {
				[cookiesDictionary setObject:value forKey:key];
			}
		}
	}	
	return cookiesDictionary;
}

#pragma mark -

//An undecoded uri portion of request.
- (void)setUri:(NSString*)aVal {
	if(uri != aVal) {
		[uri release], uri=nil;
		uri = [aVal retain];
	}
}

//The host for the webapplication
- (void)setDomain:(NSString*)domain {
	if(host != domain) {
		[host release], host=nil;
		host = [domain retain];
	}
}

//Also creates the cookies dictionary from Cookie header
- (void)setHeaders:(NSDictionary*)httpHeaders {
	if(headers != httpHeaders) {
		[headers release], headers=nil;
		headers = [httpHeaders retain];
		
		if(cookies==nil) {
			cookies = cookiesFromHeaders(headers);	//this returns a retained dictionary
		}
	}
}

//The body of the http request
- (void)setBodyDataValue:(NSData*)data {
	if(bodyDataValue!=data) {
		[bodyDataValue release], bodyDataValue=nil;
		bodyDataValue = [data retain];
	}
}

- (void)setObjectValue:(id)object {
	if(objectValue != object) {
		[objectValue release], objectValue = nil;
	}
	objectValue = [object retain];
}

//Why? maybe so we can edit a mutable request!! but thats bad...
- (void)setMethod:(NSString*)newMethod { 
	if(method != newMethod) {
		[method release], method = nil;
		method = [newMethod retain];
	}
}

- (void)setIp:(NSString*)clientIp {
	if(ip != clientIp) {
		[ip release], ip = nil;
		ip = [clientIp retain];
	}
}

//Used to set a reference to the WebResponse
- (void)setResponse:(WebResponse*)res {
	if(response!=nil) {
		froth_exception(@"WebMutableRequestException", @"WebMutableRequest response cannot be set twice.");
	}
	response = [res retain];
}

//Used by httpd connectors if needed
- (void)setInternalRequestPointer:(void*)reqPointer {
	req_p = reqPointer;
}

@end
