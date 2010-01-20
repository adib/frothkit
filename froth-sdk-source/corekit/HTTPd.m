//
//  HTTPd.m
//  FrothKit
//
//  Created by Allan Phillips on 18/01/10.
//  Copyright 2010 Thinking Code Software Inc. All rights reserved.
//

#import "HTTPd.h"
#import "WebRequest+HTTPd.h"
#import "WebApplication.h"
#import "WebResponse.h"

BOOL kLibEventInitalized;

@implementation HTTPd

- (id)initWithAddress:(NSString*)anIp port:(int)aPort application:(WebApplication*)theWebApp {
	if(self = [super init]) {
		if(!kLibEventInitalized) {
			evbase = event_init();
			kLibEventInitalized = TRUE;
		}
		
		hangingRequests = [[NSMutableArray alloc] init];
		webApp = theWebApp;
		
		ip = [anIp retain];
		port = aPort;
	}
	return self;
}

- (void)dealloc {
	//Close the server and cleanup if not done.
	[self stop];
	
	evhttp_free(httpd);
	event_base_free(evbase);
	
	[ip release], ip = nil;
	[hangingRequests release], hangingRequests = nil;
	[super dealloc];
}

- (WebApplication*)webApp {
	return webApp;
}

- (void)sendResponseForRequest:(WebRequest*)request {
	WebResponse* response = [request response];
	struct evhttp_request* req = [request internalRequestPointer];
	
	//Add in headers
	struct evkeyvalq * evheaders = evhttp_request_get_output_headers(req);
	
	NSDictionary* headers = [response headers];
	NSArray* keys = [headers allKeys];
	for(NSString* key in keys) {
		id obj = [headers objectForKey:key];
		if([obj isKindOfClass:[NSArray class]]) {
			for(id n in obj) {
				evhttp_add_header(evheaders, [key UTF8String], [n UTF8String]);
			}
		} else if([obj isKindOfClass:[NSString class]]) {
			evhttp_add_header(evheaders, [key UTF8String], [obj UTF8String]);
		} else {
			NSLog(@"+++ [[ERROR]] Incorrect cookie value for key [%@], must be NSString, or and NSArray of strings", key);
		}
	}
	
	//Add the body
	NSData* outd = [response body];
	struct evbuffer* obuff = evbuffer_new();

	if(req->type != EVHTTP_REQ_HEAD) {
		evbuffer_add(obuff, [outd bytes], [outd length]);
	}
	evhttp_send_reply(req, [response code], "no message", obuff);
	evbuffer_free(obuff);	
}

- (void)_addRequest:(WebRequest*)req {
	@synchronized(hangingRequests) {
		[hangingRequests addObject:req];
	}
}

- (void)_removeRequest:(WebRequest*)req {
	@synchronized(hangingRequests) {
		[hangingRequests removeObject:req];
	}
}

#pragma mark -
#pragma mark evhttp

void handleRequest(struct evhttp_request* req, void*arg) {
	id self = arg;
	
	WebMutableRequest* request = [[WebMutableRequest alloc] initWithEVhttp:req];	
	static SEL kHandlerMethod;
	if(!kHandlerMethod) {
		kHandlerMethod = @selector(asyncProcessRequest:);
	}
	
	[[self webApp] handle:request];
	[self sendResponseForRequest:request];
	[request release];
}

- (void)start {
	NSLog(@"++starting HTTPd on port:%i\n", port);
	
	int err;
	httpd = evhttp_new(evbase);
	if((err = evhttp_bind_socket(httpd, [ip UTF8String], port)) < 0) {
		NSLog(@"[[ERROR]] starting HTTPd on port:%i", port);
		return;
	}
	
	//Set a callback for all requests. We could have a callback per path with evhttp_set_cb..
	evhttp_set_gencb(httpd, handleRequest, self);
	evhttp_set_timeout(httpd, 5);
	
	//Start up event dispatching
	event_base_dispatch(evbase);
}

- (void)stop {
	//hmm
}


@end
