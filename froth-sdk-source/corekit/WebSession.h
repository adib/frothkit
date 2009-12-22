//
//  WebSession.h
//  Froth
//
//  Created by Allan Phillips on 16/07/09.
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
#import "WebModelBase.h"

/*!
	\brief	Provides a session object for user peristance and state management.
	\detail	The session has been abastracted from cookies and other session storage means
				to enable developers to use the desired style. For example. REST services could
				require "session" variables then use that to get the user's session, http requests
				of couse can use cookies for reteiving the user sesison.
				
				<br><br>
				Sessions can be added key/value data that can be used with a session. The value must always
				implement the JSON protocal for serailizing as json. Any object that does this can then be added
				to a session. An Example of this could be the authentication system's user info. The username/userobject
				could be stored in the session with...
				<br>[aSession setValue:user forKey:@"user"];
				<br>Or retreived with...
				<br>[aSession valueForKey:@"user"];
				
				<br><br>
				Sessions are persisted according to the webApp's datasource's SessionDataSource key
				see WebDataSource/WebModelBase for more details. The default datasource is the MemoryDataSource
				and is optionally overidable by adding a datasource listing to DataSources.plist with name
				SessionStorage
 
				<br><br>
				WebSession instances use an internal json structure to persist session properties. This allows
				persistance in mysql/memchache or any other datasource. The JSON utility is heavily used to provide for
				this functionality.
 
				<br><br>
				WebSessions should not be subclassed. Becouse Froth provides internal methods for automatically retreiveing
				the session for a given request, it can be difficult to use your own implementation.
 
				<br><br>
				Sessions can be copyied as they inherit WebModelBase's NSCopying protocal support. Note however that the guid
				or session key is not copied, only the storage.
 
				<br><br>
				Catagories are the best way to extend web sessions and to provide cusomized accessors for starage data.
 
				<br><br>
				Sessions are retrieved from a request by the following logic, in order if the previous attempt fails to
				return a session value.
				1. Check the cookies for a x-froth-session key/value pair.
				2. Check for a x-froth-session HTTP enviorment header (Can be used for built in sessionful/rest api).
				3. Check for a /xfrothsession/value params combo in the request's url
				4. If the url-encoded post contains a xfrothsession=value combination
 
				<br><br>
				Sessions are retrieved dynamically when the user asks for it in a controller action. This provides a faster
				on-demand implemtation, for times when a session key is not needed. WebRequest provides the property -session for
				accessing the current sesison. (This returns nil if no session availible.)
 
				<br><br>
				Sessions are dynamically generated as needed for normal html web requests (non api) These are always set to expire
				at a set time as the application defualts. These are created if needed, or useing existing. If 
 
				<br><br>
				REST/APIs can also generate a session and retreive it with the method (Unless overide by a controller class that uses
				the name [session]...
				http://[host]/[path-to-froth]/session/get
 */
@interface WebSession : WebModelBase {
	NSString* guid;
}
@property (nonatomic, retain) NSString* guid;
@property (nonatomic, retain) NSString* storage;
@property (readonly, retain) NSArray* storageKeys;

+ (WebSession*)sessionWithKey:(NSString*)sessionKey;

/*! \brief Returns a new retained/unsaved session with the given session key */
+ (WebSession*)newSessionWithKey:(NSString*)sessionKey;

/*! \brief Value must be able to seralize itself as a string with -stringValue or -description (NSNumber) */
//- (void)setValue:(id)value forKey:(NSString*)key;
//- (id)valueForKey:(NSString*)key;
//- (id)valueForKeyPath:
- (void)removeValueForKey:(NSString*)key;

@end
