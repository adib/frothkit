//
//  WebRequest.m
//  Froth
//
//  Created by Crystal Phillips on 26/06/09.
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
#import "WebRequest.h"
#import "DDXML.h"
#import "JSON.h"
#import "NSDictionary+Query.h"
#import "Froth+Defines.h"
#import "Froth+Exceptions.h"
#import "WebApplication.h"
#import "NSString+Utilities.h"
#import "WebResponse.h"

@implementation WebRequest

- (id)init {
	if(self = [super init]) {
		keepAlive = FALSE;
	}
	return self;
}

- (NSString*)description {
	NSMutableString* str = [NSMutableString string];
	[str appendFormat:@"%@ ", self.method];
	[str appendFormat:@"%@ ", self.uri];
	[str appendFormat:@"%@", self.ip];
	return str;
}

- (void)dealloc {
	[uri  release], uri = nil;
	[queryString release], queryString = nil;
	[host release], host = nil;
	[ip release], ip = nil;
	
	[method release]; method = nil;
	[cookies release]; cookies = nil;
	[query release]; query = nil;
	[headers release]; headers = nil;
	[extension release]; extension = nil;
	
	[controller release]; controller = nil;
	[action release]; action = nil;
	
	//TODO: Not sure whats up with mem-management here. This is causing a sigfault.
	/*[bodyDataValue release]; bodyDataValue = nil;*/
	[objectValue release]; objectValue = nil;
	
	[params release]; params = nil;
	[session release]; session = nil;
	[response release]; response = nil;
	
	[super dealloc];
}

#pragma mark -
#pragma mark Basic HTTP Request Info

- (NSString*)url {
	NSLog(@"+++ [[DEPRECIATED]] WebRequest -url is depreciated, use -uri instead");
	return [self uri];
}

- (NSString*)uri {
	/*	Provides support for if the httpd connector sets the ivar, or 
	 if their are retreived from environment variables (FastCGI) */
	if(uri==nil) {
		uri = [[[self headers] objectForKey:@"REQUEST_URI"] retain]; //For FASTCGI
		if(uri == nil) {
			uri = @"/"; //What!?
		}
	}
	return uri;
}

- (NSString*)domain {
	if(host==nil) {
		host = [[[self headers] objectForKey:@"SERVER_NAME"] retain];
	}
	return host;
}

- (NSDictionary*)headers {
	return headers;
}

- (WebSession*)session {
	if(!session) {
		/* See WebSession's header for rules of getting the seesion key from a request */
		id sessionKey = [self valueForCookie:@"x-froth-session"];

		if(!sessionKey) {
			sessionKey = [[self headers] valueForKey:@"X-FROTH-SESSION"];
		}
		
		if(!sessionKey) {
			//FastCGI forwarded headers
			sessionKey = [[self headers] valueForKey:@"HTTP_X_FROTH_SESSION"];
		}
		
		//May have multiple session keys lingering in cookies under extrenious situations
		if(sessionKey && [sessionKey isKindOfClass:[NSArray class]]) {
			sessionKey = [sessionKey objectAtIndex:0];	//err.
		}
		
		if(!sessionKey && [self.action isEqualToString:@"xfrothsession"]) {
			//This could through an exception
			sessionKey = [self.params objectAtIndex:0];
		}
		
		if(!sessionKey) {
			NSInteger index = [self.params indexOfObject:@"xfrothsession"];
			if(index != NSNotFound) {
				sessionKey = [self.params objectAtIndex:index+1];
			}
		}
		
		//Get an existing persisted session
		session = [[WebSession sessionWithKey:sessionKey] retain];
		
		//Finally, if no session info, generate new.
		if(!session) {
			session = [WebSession newSessionWithKey:sessionKey];
		}
	}
	return session;
}

- (NSString*)extension {
	if(extension == nil) {
		NSString* path = [uri stringByReplacingOccurrencesOfString:froth_str(@"?%@", [self queryString]) withString:@""];
		extension = [[path pathExtension] retain];
		
		if(extension && extension.length < 1) {
			[extension release], extension = nil;
		}
	}
	return extension;
}

- (NSData*)bodyDataValue {
	return bodyDataValue;
}

- (NSDictionary*)cookies {
	return cookies;
}

- (NSString*)method {
	if(method==nil)	{
		method = [[[self.headers objectForKey:@"REQUEST_METHOD"] uppercaseString] retain];
	}
	return method;
}

- (NSString*)contentType {
	return [self.headers objectForKey:@"CONTENT_TYPE"];
}

- (NSString*)queryString {
	if(queryString==nil) {
		NSArray* comps = [self.uri componentsSeparatedByString:@"?"];
		if(comps.count>1) {
			queryString = [[comps objectAtIndex:1] retain];
		}
	}
	return queryString;
}

- (NSDictionary*)query {
	if(query == nil) {
		NSString* qStr = [self queryString];
		if(!qStr) {
			qStr = [self.headers valueForKey:@"QUERY_STRING"];
		}
		query = [[NSDictionary dictionaryWithQuery:qStr] retain];
	}
	return query;
}

#pragma mark -
#pragma mark Body and Deseralization

//??? Is this needed
- (NSString*)bodyStringValue {
	return [[NSString alloc] initWithData:self.bodyDataValue encoding:NSUTF8StringEncoding];
}

- (id)objectValue {
	if(objectValue != nil) {
		return objectValue;
	}
	
	if([self.method isEqualToString:@"GET"]) {
		objectValue = [[self query] retain];
	} else {	
		NSString* contentType = [self contentType];
		NSString* ext = [self extension];

		NSString* bodyString = [[NSString alloc] initWithData:self.bodyDataValue encoding:NSUTF8StringEncoding];
		
		if([ext isEqualToString:@"json"] || [contentType hasPrefix:@"application/json"] || [contentType hasPrefix:@"text/json"]) {
			objectValue = [[bodyString JSONValue] retain];
		} else if([ext isEqualToString:@"xml"] || [contentType hasPrefix:@"application/xml"] || [contentType hasPrefix:@"text/xml"]) {
			
			NSError* error = nil;
			objectValue = [[NSXMLDocument alloc] initWithXMLString:bodyString options:0 error:&error];
			if(error) {
				objectValue = [[NSXMLElement alloc] initWithXMLString:bodyString error:nil];
				[error release];
			}
			
		} else if([contentType hasPrefix:@"application/x-www-form-urlencoded"] || 
				  [contentType hasPrefix:@"text/x-www-form-urlencoded"] ||
				  [contentType hasPrefix:@"x-www-form-urlencoded"]) {
			//TODO: parse into dictionary
			objectValue = [[NSDictionary dictionaryWithPostForm:bodyString] retain];
		} else if([contentType hasPrefix:@"text/plain"] || [contentType hasPrefix:@"text/html"] || [contentType hasPrefix:@"text/richtext"]) {
			objectValue = [bodyString retain];
		} else {
			objectValue = nil;
		}
		[bodyString release];
		
	}
	
	return objectValue;
}

- (NSString*)valueForCookie:(NSString*)cookieKey {
	return [self.cookies objectForKey:cookieKey];
}

- (NSString*)valueForHeader:(NSString*)headerName {
	return [self.headers valueForKey:headerName];
}

#pragma mark -
#pragma mark Controller/Action/Param Getters

- (void)_prepareControllerActionParamsProperties {
	if(!controller && !action) {
		NSString* path = [uri stringByReplacingOccurrencesOfString:froth_str(@"?%@", [self queryString]) withString:@""];
		
		NSString* localUri;
		NSString* appUriRoot = [WebApplication deploymentUriPath];
		if(appUriRoot) {
			localUri = [path stringByReplacingOccurrencesOfString:appUriRoot withString:@""];
		} else {
			localUri = appUriRoot;
		}
		
		NSArray* pcomps = [[localUri stringByDeletingPathExtension] pathComponents];
		if([pcomps count] > 0) {
			NSMutableArray* parts = [NSMutableArray arrayWithArray:pcomps];
			params = [[NSMutableArray alloc] init];
			
			while(parts.count>0) {
				NSString* nextPart = [parts objectAtIndex:0];
				if([nextPart length]>0 && ![nextPart isEqualToString:@"/"]) {
					if(controller == nil) {
						controller = [nextPart retain];
					} else if(action == nil) {
						action = [[nextPart underscoreToCamelCase] retain];
					} else {
						[params addObject:[nextPart stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
					}
				}
				[parts removeObject:nextPart];
			}
		} else {
			//Get defualt controller/action from configuration
			NSDictionary* conf = [[NSBundle mainBundle] infoDictionary];
			NSString* defCont = [conf valueForKey:@"froth_default_controller"];
			NSString* defAct = [conf valueForKey:@"froth_default_action"];
			if(defCont == nil || defCont.length < 1) {
				defCont = @"home";
			}
			controller = [defCont retain];
			action = (defAct.length>0)?[defAct retain]:nil;
		}
	}
}

- (NSString*)controller {
	if(controller == nil) {
		[self _prepareControllerActionParamsProperties];
	}
	return controller;
}

- (NSString*)action {
	if(action == nil) {
		[self _prepareControllerActionParamsProperties];
	}
	return action;
}

- (NSMutableArray*)params {
	if(params == nil) {
		[self _prepareControllerActionParamsProperties];
	}
	return params;
}

- (NSString*)ip {
	if(ip==nil) {
		ip = [[[self.headers valueForKey:@"REMOTE_ADDR"] stringByReplacingOccurrencesOfString:@"::ffff:" withString:@""] retain];
	}
	return ip;
}

#pragma mark -

- (WebResponse*)response {
	return response;
}

- (void*)internalRequestPointer {
	return req_p;
}

- (BOOL)keepAlive {
	return keepAlive;
}

- (void)setKeepAlive:(BOOL)alive {
	keepAlive = alive;
}

@end
