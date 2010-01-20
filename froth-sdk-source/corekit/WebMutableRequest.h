//
//  WebMutableRequest.h
//  FrothKit
//
//  Created by Allan Phillips on 19/01/10.
//  Copyright 2010 Thinking Code Software Inc. All rights reserved.
//

#import "WebRequest.h"

/*	
	\brief	Provides a mutable web request for use with Web HTTP connectors
	This is typically only used by http connectors for creating the request object.
 */
@interface WebMutableRequest : WebRequest {

}
//An undecoded uri portion of request.
- (void)setUri:(NSString*)url;

//The host for the webapplication
- (void)setDomain:(NSString*)domain;

//Also creates the cookies dictionary from Cookie header
- (void)setHeaders:(NSDictionary*)httpHeaders;

//The body of the http request
- (void)setBodyDataValue:(NSData*)data;

//For custom generated objectValue
- (void)setObjectValue:(id)object;

//The http method (GET, POST, PUT, DELETE, HEAD)
- (void)setMethod:(NSString*)httpMethod;

//The ip address of the requestor;
- (void)setIp:(NSString*)clientIp;

//Used to set a reference to the WebResponse
- (void)setResponse:(WebResponse*)res;

//Used by httpd connectors if needed
- (void)setInternalRequestPointer:(void*)reqPointer;

@end
