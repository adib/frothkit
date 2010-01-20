//
//  WebRequest.h
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

#import <Foundation/Foundation.h>
#import "WebSession.h"

@class WebResponse;

/*! 
	\brief	Encapsulates information from a request from httpd (or fastcgi)
		
				Requests have convienence methods for accessing an object value from the
				body or query of the request. 
 
				\code
				-(id)objectValue;
				\endcode
				
				<h3>POST/PUT Requests</h3>
				For POST requests, -objectValue returns an object automatically decoded from the http request's body, be it xml,
				json, html, x-www-form-urlencoded, etc. For post content the object returned from -objectValue will be a NSXMLElement, 
				for json the result will be a NSDictionary. Text content will return as a NSString from the -objectValue method. 
				
				WebRequest parses the data useing the following logic.<br>
				- Checks the http contentType header with application/json or text/json, application/xml or text/xml and x-www-form-urlencoded.<br>
				- Checks the extention of the request *.xml, *.json and uses the extention as the type.
 
				<h3>GET Requests</h3>
				For GET Reqeusts -objectValue returns the query (?this=that) part of the url, or nil if none.
 
				CHANGES:
				- V0.5.0 -url is depreciated, use -uri instead
 */
@interface WebRequest : NSObject {
	NSString* uri;
	NSString* queryString;
	NSString* host;
	NSString* ip;
	
	NSString* method;
	NSString* controller;
	NSString* action;
	NSString* extension;
	NSMutableArray* params;
	
	NSDictionary* headers;
	NSDictionary* cookies;
	NSDictionary* query;
		
	NSData* bodyDataValue;
	id objectValue;

	WebSession* session;
	WebResponse* response;
	
	BOOL keepAlive;
	
	//pointer to c request structure (Only currently HTTPd)
	void* req_p;
}

//	NOTE: The internal design of WebRequest needs more overhaul to abstract it from the http connector type (fastcgi/http...)


/*! \brief [DEPRECIATED use -uri] This is incorrectly named url, should be path and a url method should be implemented. */
- (NSString*)url __attribute__((deprecated));

/*! \brief An un-decoded uri portion of the request including the query */
- (NSString*)uri;

/*! \brief The domain name for the web application from the 'Host' http header */
- (NSString*)domain;

/*! \brief The http method for the request. (GET | POST | PUT | DELETE ...) */
- (NSString*)method;

/*! \brief HTTP request headers as a dictionary */
- (NSDictionary*)headers;

/*! 
	\brief	The file extention for the request's path.
	\return	nil if no path.
 */
- (NSString*)extension;

/*! \brief Raw data from a post request's body */
- (NSData*)bodyDataValue;

/*! \brief The raw name for mapping to a WebController */
- (NSString*)controller;

/*! \brief The raw name for mapping to a WebController -method */
- (NSString*)action;

/*! \brief Represents any paramiters send after the request (ie {controllerName}/{actionName}/{actionParams[0]/...} */
- (NSMutableArray*)params;

/*! \brief HTTP Cookies from request header */
- (NSDictionary*)cookies;

/*! \brief The request header's Content-Type if any. */
- (NSString*)contentType;

/*! \brief Post body as a string using utf8 decoded. */
- (NSString*)bodyStringValue;

/*! \brief	The posts body where object class is dependent on "contentType"
				
				This object is automatically created from the contentType for the object
				
				1. application/json | text/json				- NSDictionary or NSArray
				2. text/plain | text/html | text/richtext	- NSString
				3. application/xml | text/xml				- NSXMLDocument
				
				//TODO: convert text/html to DOMHtml object for server side dom support
 */
- (id)objectValue;

/*! \brief The session based on user for request (See WebSession header info) for how this is handled */
- (WebSession*)session;

/*! \brief The string query portion of the request */
- (NSString*)queryString;

/*! \brief The request query ?this=that&here=their as a dictionary*/
- (NSDictionary*)query;

/*! \brief Convenience method for accessing a cookie value with given key name, (uses request.cookies dictionary storage) */
- (NSString*)valueForCookie:(NSString*)cookieName;

/*! \brief Returns a header value for header key, IE HTTP_HOST */
- (NSString*)valueForHeader:(NSString*)headerName;

/*! \brief Convenience method for returning environment variable for requestors ip address. */
- (NSString*)ip;

/*! \brief Returns a generated response for the request. */
- (WebResponse*)response;

/*! \brief The internal request pointer */
- (void*)internalRequestPointer;

/*!
	\brief	[Not Implemented] If the request should be kept alive for asynchronous communications.
 
	See -setKeepAlive or -setKeepAliveForInterval:
 */ 
- (BOOL)keepAlive;

/* 
	\brief [Not Implemented] If the connection should be kept alive for asynchronous communications
 
	 This can be used to enable aync features in a froth application. Prior to return the web response to
	 the WebApplication either in an action method, component handle or pre/post preocessing controller methods,
	 a WebRequest can be set to 'true' to enable a chunked data (Content-Transmission: Chunked) mode or some other
	 streaming mode.
 */
- (void)setKeepAlive:(BOOL)alive;

@end
