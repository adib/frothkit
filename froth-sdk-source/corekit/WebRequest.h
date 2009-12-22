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

/*! 
	\brief	Encapsulates information from a request from httpd (or fastcgi)
	\detail	WebRequests provide a Action controller with all the details about a request,
				also it typically containts routing information applied by the server.
				<br><br>
				Requests also has convienence methods for accessing a NSDictionary/NSArray from the
				body or query of the request.
				<br>
				<h3>POST/PUT Requests</h3>
				For POST requests, -objectValue returns an object automatically decoded from the http request's body, be it xml,
				json, html, x-www-form-urlencoded, etc. For post content the object returned from -objectValue will be a NSXMLElement, 
				for json the result will be a NSDictionary. Text content will return as a NSString from the -objectValue method. 
				
				WebRequest parses the data useing the following logic.<br>
				1. Checks the http contentType header with application/json or text/json, application/xml or text/xml and x-www-form-urlencoded.<br>
				2. Checks the extention of the request *.xml, *.json and uses the extention as the type.
 
				<h3>GET Requests</h3>
				For GET Reqeusts -objectValue returns the query (?this=that) part of the url, or nil if none.
 
 
 */
@interface WebRequest : NSObject {
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

}
- (NSString*)url;
- (NSString*)domain;
- (NSString*)method;
- (void)setMethod:(NSString*)replacement;
- (NSDictionary*)headers;
- (NSString*)extension;

/*! \brief Raw data from a post request's body */
- (NSData*)bodyDataValue;

/*! \brief The raw name for mapping to a WebController */
- (NSString*)controller;

/*! \brief The raw name for mapping to a WebController -method */
- (NSString*)action;

/*! \brief Represents any paramiters send after the request (ie {controllerName}/{actionName}/{actionParams[0]/...} */
- (NSMutableArray*)params;

- (NSDictionary*)cookies;

/*! \brief The request header's Content-Type if any. */
- (NSString*)contentType;

/*! \brief Post body as a string using utf8 decoded. */
- (NSString*)bodyStringValue;

/*! \brief	The posts body where object class is dependent on "contentType"
	\detail	This object is automatically created from the contentType for the object
				
				1. application/json | text/json				- NSDictionary or NSArray
				2. text/plain | text/html | text/richtext	- NSString
				3. application/xml | text/xml				- NSXMLDocument
				
				//TODO: convert text/html to DOMHtml object for server side dom support
 */
- (id)objectValue;
- (void)setObjectValue:(id)object;

/*! \brief The session based on user for request (See WebSession header info) for how this is handled */
- (WebSession*)session;

/*! \brief The request query ?this=that&here=their as a dictionary*/
- (NSDictionary*)query;

/*! \brief Convenience method for accessing a cookie value with given key name, (uses request.cookies dictionary storage) */
- (NSString*)valueForCookie:(NSString*)cookieName;

/*! \brief Returns a header value for header key, IE HTTP_HOST */
- (NSString*)valueForHeader:(NSString*)headerName;

/*! \brief Convenience method for returning enviorment variable for requestors ip address. REMOTE_ADDR */
- (NSString*)ip;

@end
