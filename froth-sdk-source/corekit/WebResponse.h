//
//  WebResponse.h
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

#import <Foundation/Foundation.h>

/*!
	\brief Provides a final wrapper on an http response 
 */
@interface WebResponse : NSObject {
	NSUInteger code;
	NSMutableDictionary* headers;
	NSData* body;
}
@property (nonatomic, assign) NSUInteger code;
@property (nonatomic, retain) NSMutableDictionary* headers;
@property (nonatomic, retain) NSData* body;

// body as UTF8 string
@property (nonatomic, retain) NSString* bodyString;

+ (WebResponse*)okResponse;
+ (WebResponse*)forbiddenResponse;
+ (WebResponse*)notFoundResponse;
+ (WebResponse*)responseWithCode:(NSUInteger)code;

+ (WebResponse*)htmlResponse;
+ (WebResponse*)htmlResponseWithBody:(NSString*)bodyString;

+ (WebResponse*)jsonResponse;

/*!
	\brief		Convenience method for creating a response with content-Type: text/x-json
	\param		bodyString A json formatted string.
*/				
+ (WebResponse*)jsonResponseWithBody:(NSString*)bodyString;

+ (WebResponse*)xmlResponse;

/*!
	\brief		Convenience method for creating a response with content-Type: text/xml
		\param		bodyString A xml formatted string.
 */	
+ (WebResponse*)xmlResponseWithBody:(NSString*)bodyString;

/*!
	\brief		Convenience method for creating a redirection response with http response code 303.
	\param		fullUrl A full url including schema.
 */	
+ (WebResponse*)redirectResponseWithUrl:(NSString*)fullUrl;

/*!
	\brief		Used to set http header properties
	\param		value The value to set.
	\param		headerKey The keyname for the http response header.
 */
- (void)setHeader:(NSString *)value forKey:(NSString *)headerKey;

/*!
	\brief		Provides cookie setting support.
	
				Multiple cookies can be set for a single response, setting a new cookie overwrites the old.
				If a cookie was previously set with an expiration date, users can pass nil for all cookie params
				to only change the value itself.
 
				See WebRequest -valueForCookie:(NSString*)cookieKey for accessing cookies
			
	@param		expireDate	
				Optional expiration date as used by browsers
	@param		isSecure
				If the cookie should only be sent over a secure connection to the server.
	@param		domain
				The domain for the cookie if different then the request's domain.
	@param		path
				The path for the cookie if different then the requesting path.
 */

- (void)setCookieValue:(NSString*)value 
				forKey:(NSString*)key 
			   expires:(NSDate*)expireDate 
				secure:(BOOL)isSecure 
				domain:(NSString*)domain
				  path:(NSString*)path;

- (NSData *)dump;

@end
