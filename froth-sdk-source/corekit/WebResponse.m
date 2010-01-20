//
//  WebResponse.m
//  Froth
//
//  Created by Allan Phillips on 09/07/09.
//
//  Copyright (c) 2009 Thinking Code Software Inc. http://www.thinkingcode.ca
//
//	Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//	files (the "Software"), to deal in the Software without
//	restriction, including without limitation the rights to use,
//	copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the
//	Software is furnished to do so, subject to the following
//	conditions:

//	The above copyright notice and this permission notice shall be
//	included in all copies or substantial portions of the Software.

//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//	EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//	OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//	NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//	HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//	OTHER DEALINGS IN THE SOFTWARE.

#import "WebResponse.h"
#import "WebRequest.h"

@implementation WebResponse
@synthesize code;
@synthesize headers;
@synthesize body;

- (void)dealloc {
	[headers release];
	[body release];
	[super dealloc];
}

- (NSString*)bodyString {
	if(self.body) {
		return [[[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding] autorelease];
	}
	return nil;
}

- (void)setBodyString:(NSString*)string {
	self.body = [string dataUsingEncoding:NSUTF8StringEncoding];
}

#pragma mark -
- (id)initWithCode:(NSUInteger)aCode contentType:(NSString*)contentType {
	if(self = [super init]) {
		headers = [[NSMutableDictionary alloc] init];
		self.code = aCode;

		if(contentType) {
			[self setHeader:contentType forKey:@"Content-Type"];
		}
	}
	return self;
}

+ (WebResponse*)okResponse {
	return [[[self alloc] initWithCode:200 contentType:nil] autorelease];
}

+ (WebResponse*)forbiddenResponse {
	return [[[self alloc] initWithCode:403 contentType:nil] autorelease];
}

+ (WebResponse*)notFoundResponse {
	return [[[self alloc] initWithCode:404 contentType:nil] autorelease];
}

+ (WebResponse*)responseWithCode:(NSUInteger)aCode {
	return [[[self alloc] initWithCode:aCode contentType:nil] autorelease];
}

+ (WebResponse*)htmlResponse {
	return [[[self alloc] initWithCode:200 contentType:@"text/html"] autorelease];
}

+ (WebResponse*)htmlResponseWithBody:(NSString*)bodyString {
	WebResponse* res = [[self alloc] initWithCode:200 contentType:@"text/html"];
	res.bodyString = bodyString;
	return [res autorelease];
}

+ (WebResponse*)jsonResponse {
	return [[[self alloc] initWithCode:200 contentType:@"text/x-json"] autorelease];
}

+ (WebResponse*)jsonResponseWithBody:(NSString*)bodyString {
	WebResponse* res = [[self alloc] initWithCode:200 contentType:@"text/x-json"];
	res.bodyString = bodyString;
	return [res autorelease];
}

+ (WebResponse*)xmlResponse {
	return [[[self alloc] initWithCode:200 contentType:@"text/xml"] autorelease];
}

+ (WebResponse*)xmlResponseWithBody:(NSString*)bodyString {
	WebResponse* res = [[self alloc] initWithCode:200 contentType:@"text/xml"];
	res.bodyString = bodyString;
	return [res autorelease];
}

+ (WebResponse*)redirectResponseWithUrl:(NSString*)fullUrl {
	WebResponse* redirect = [WebResponse responseWithCode:303];
	[redirect setHeader:fullUrl forKey:@"Location"];
	return redirect;
}

- (void)setHeader:(NSString *)h forKey:(NSString *)s {
	[headers setObject:h forKey:s];
}

#pragma mark -
#pragma mark Cookie Support

- (void)setCookieValue:(NSString*)value 
				forKey:(NSString*)key 
			   expires:(NSDate*)expireDate 
				secure:(BOOL)isSecure 
				domain:(NSString*)domain
				  path:(NSString*)path {
	NSMutableString* cs = [NSMutableString string];
	[cs appendFormat:@"%@=%@", key, value];
	
#ifdef __APPLE__
	if(expireDate) {
		NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
		[formatter setDateFormat:@"EEE, dd-MM-yyyy HH:mm:ss zzz"];
		[formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0.0]];
		NSString* dateStr = [formatter stringFromDate:expireDate];
		[cs appendFormat:@"; expires=%@", dateStr];
		[formatter release];
	}
#endif
	
	if(domain) {
		[cs appendFormat:@"; domain=%@", domain];
	}
	
	if(path) {
		[cs appendFormat:@"; path=%@", path];
	}
	
	if(isSecure) {
		[cs appendFormat:@"; secure"];
	}
	
	NSArray* array = nil;
	id cookies = [[self headers] objectForKey:@"Set-Cookie"];
	if(cookies && [cookies isKindOfClass:[NSArray array]]) {
		array = [(NSArray*)cookies arrayByAddingObject:cs];
	} else if(cookies) {
		array = [NSArray arrayWithObjects:cookies, cs, nil];
	} else {
		array = [NSArray arrayWithObject:cs];
	}
	[[self headers] setObject:array forKey:@"Set-Cookie"];

}

#pragma mark -
#pragma mark Raw Writout to Http

- (void)_prepareHeaders {
	if(![headers objectForKey:@"Content-Type"]) {
		[headers setObject:@"text/html" forKey:@"Content-Type"];
	}
}

- (NSData *)dump {
	[self _prepareHeaders];
	NSMutableData *d = [[NSMutableData alloc] init];
	for(NSString *k in headers) {
		id headerObject = [headers objectForKey:k];
		
		//Provides support for multiple header with same header name (ie Set-Cookie: headers)
		if([headerObject isKindOfClass:[NSArray class]]) {
			for(NSString* nValue in headerObject) {
				const char *ck = [k UTF8String];
				[d appendBytes:ck length:strlen(ck)];
				[d appendBytes:": " length:2];
				const char *cv = [nValue UTF8String];
				[d appendBytes:cv length:strlen(cv)];
				[d appendBytes:"\n" length:1];
			}
		} else {
			const char *ck = [k UTF8String];
			[d appendBytes:ck length:strlen(ck)];
			[d appendBytes:": " length:2];
			const char *cv = [[headers objectForKey:k] UTF8String];
			[d appendBytes:cv length:strlen(cv)];
			[d appendBytes:"\n" length:1];
		}
	}
	[d appendBytes:"\n" length:1];
	//const char *cb = [body UTF8String];
	//if(cb) {
	//	[d appendBytes:cb length:strlen(cb)];
	//}
	
	//HEAD requests do not return request body.
	if([self body] != nil) {
		[d appendData:body];
	}
		
	[d appendBytes:"\0" length:1];
	return [d autorelease];
}

@end
