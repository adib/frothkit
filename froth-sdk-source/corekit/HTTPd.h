//
//
//  HTTPd.h
//  Froth
//
//	 Created by Allan Phillips
//
//  Copyright (c) 2010 Thinking Code Software Inc. http://www.thinkingcode.ca
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

#import <Foundation/Foundation.h>
#import <sys/queue.h>
#import <evhttp.h>

@class WebApplication;

/*! 
	\brief [EXPERIMENTAL] A single threaded httpd server that wraps libevent's http functions 
 
	\code
	int main(....) {
			NSAutoReleasePool* pool = [[NSAutoReleasePool alloc] init];
				
			WebApplication* webApp = [[WebApplication alloc] init];
			HTTPd* httpd = [[HTTPd alloc] initWithAddress:@"34.123.12.1" port:80 application:webApp]l
			[httpd start];	//Blocks
		
			[pool release];
			return 0;
	}
	\endcode
	
 */
@interface HTTPd : NSObject {
	NSString* ip;
	int port;
	
	struct event_base *evbase;
	struct evhttp *httpd;
	
	NSMutableArray* hangingRequests;
	NSMutableArray* requestPool;
	
	WebApplication* webApp;
	
	NSThread* httpdThread;
	NSMutableArray* workerTheadPool;
}

- (id)initWithAddress:(NSString*)ip port:(int)port application:(WebApplication*)webApp;
- (void)start;

//Does nothing
- (void)stop;

@end
