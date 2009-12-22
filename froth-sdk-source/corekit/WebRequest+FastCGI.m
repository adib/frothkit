//
//  WebRequest+FastCGI.m
//  FrothKit
//
//  Created by Allan Phillips on 09/12/09.
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
//
//	Portions Copyright (c) 2008 Vladimir "Farcaller" Pouzanov <farcaller@gmail.com>

#import "WebRequest+FastCGI.h"
#import "Froth+Exceptions.h"
#import "NSDictionary+Query.h"

@implementation WebRequest (FastCGI)

- (void)setHTTPRequestPointer:(char**)env {
	char **p;
	
	NSMutableDictionary* e = [[NSMutableDictionary alloc] init];
	NSMutableDictionary* c = [[NSMutableDictionary alloc] init];
	
	for(p=env; *p!=NULL; ++p) {
		NSString *s = [[NSString alloc] initWithUTF8String:*p];
		
		//For security purposes
		NSRange sp = [s rangeOfString:@"="];
		if(sp.location == NSNotFound) {
			[e release], [c release];
			froth_exception(@"BadEnvironmentException", [NSString stringWithFormat:@"Option \"%@\" does not contain field separator", [s autorelease]]);
		}
		
		//Parse header values
		NSString* value = nil;
		if([s hasPrefix:@"HTTP_COOKIE="]) {
			value = [s stringByReplacingOccurrencesOfString:@"HTTP_COOKIE=" withString:@""];
			[e setObject:value forKey:@"HTTP_COOKIE"];
			
			NSArray* keyValues = [value componentsSeparatedByString:@"; "];
			for(NSString* kv in keyValues) {
				NSArray* parts = [kv componentsSeparatedByString:@"="];
				[c setObject:[parts objectAtIndex:1] forKey:[parts objectAtIndex:0]];
			}
			cookies = [c retain];
		} else {
			
			/*
			 TODO: Apple Memory Leak Fix
			 For some reason their is a leak in Apple's implemention of substringFromIndex: to
			 Fix that we will do array spliting instead as it appears to have no leak... not ideal by any means...
				
			 [e setObject:[s substringFromIndex:sp.location+1] forKey:[s substringToIndex:sp.location]];
			 */
			
			NSArray* parts = [s componentsSeparatedByString:@"="];
			NSString* key = [parts objectAtIndex:0];
			value = [s stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@=", key] withString:@""];
			[e setObject:value forKey:key];
		}
		[s release];
	}
	
	headers = [e retain];
	
	[e release];
	[c release];
}

- (void)setBodyData:(NSData*)data {
	bodyDataValue = [data retain];
}

@end
