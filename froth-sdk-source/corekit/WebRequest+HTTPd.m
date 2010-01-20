//
//  WebRequest+HTTPd.m
//  FrothKit
//
//  Created by Allan Phillips on 18/01/10.
//  Copyright 2010 Thinking Code Software Inc. All rights reserved.
//

#import "WebRequest+HTTPd.h"


@implementation WebMutableRequest (HTTPd)

NSString* httpMethodFromRequest(struct evhttp_request* req) {
	switch (req->type) {
		case EVHTTP_REQ_GET:
			return @"GET";
		case EVHTTP_REQ_HEAD:
			return @"HEAD";
		case EVHTTP_REQ_POST:
			return @"POST";
		case EVHTTP_REQ_PUT:
			return @"PUT";
		case EVHTTP_REQ_DELETE:
			return @"DELETE";
		default:
			return @"UNDEFINED";
	}
}

NSString* httpUriFromRequest(struct evhttp_request* req) {
	const char* euri = evhttp_request_uri(req);
	//evhttp_decode_uri(euri) -- could use this to decode..
	return [NSString stringWithUTF8String:euri];
}

NSDictionary* headersFromRequest(struct evhttp_request* req) {
	NSMutableDictionary* headersDictionary = [[NSMutableDictionary alloc] initWithCapacity:30];
	struct evkeyvalq* headers = req->input_headers;
	struct evkeyval* np;
	TAILQ_FOREACH(np, headers, next) {
		[headersDictionary setObject:[NSString stringWithUTF8String:np->value] forKey:[NSString stringWithUTF8String:np->key]];
	}
	return headersDictionary;
}

- (id)initWithEVhttp:(struct evhttp_request*)evreq {
	if(self = [super init]) {
		NSDictionary* hheaders = headersFromRequest(evreq); //retained
		[self setHeaders:hheaders];
		[hheaders release];
				
		[self setDomain:[headers valueForKey:@"Host"]];
		[self setUri:httpUriFromRequest(evreq)];
		[self setMethod:httpMethodFromRequest(evreq)];
		[self setIp:[headers valueForKey:@"X-Forwarded-For"]];
		
		//Get the body data if POST/PUT
		if(evreq->type == EVHTTP_REQ_POST || evreq->type == EVHTTP_REQ_PUT) {
			struct evbuffer* inbuf = evhttp_request_get_input_buffer(evreq);
			void* rdata;
			size_t l;
			if((l=evbuffer_remove(inbuf, &rdata, evbuffer_get_length(inbuf)))>0) {
				[self setBodyDataValue:[NSData dataWithBytes:rdata length:l]];
			} else {
				NSLog(@"An error occured reading body buffer for request");
			}
		}
		
		//Give the WebRequest a reference to the evhttp request pointer
		[self setInternalRequestPointer:evreq];
	}
	return self;
}

@end
