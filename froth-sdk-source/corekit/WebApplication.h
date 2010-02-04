//
//  ApplicationController.h
//  Froth
//
//  Created by Allan Phillips on 23/02/09.
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

#import "WebRequest.h"
#import "WebResponse.h"
#import "WebLayoutView.h"
#import "WebActionView.h"

/*!
	\brief	A WebApplication object manages the request/response cycle between the httpd server and web application controllers instances. 
 
	CHANGES:
 */
@interface WebApplication : NSObject {
	@private
	NSMutableArray* m_cachedWebActionControllerClasses;
	NSString*		m_app_path;
	WebLayoutView*	m_defualtLayoutView;
	WebActionView*	m_defualtActionView;
	
	Class m_delegateClass;
	id delegate;
	
	NSMutableDictionary* m_componentInstances;
}

/*!
	\brief	Designated initializer
 */
- (id)init;

/*!
	\brief	Returns the deployment mode name for the current running application. 
			
	This is determined by looking at the app bundle's parent folder name. This, by design, is the deployment mode.
 */
+ (NSString*)deploymentMode;

/*!
	\brief	Returns the web path to the currently running app, typically '/' for root
	
	NEW: The deployment path is from the bundle's Deployments.plist dictionary Modes.[mode].Root setting
	OLD: The deployment path is the value of Info.plist (or Info-Mac.plist)'s froth_root_(deploymentMode) key.
 */
+ (NSString*)deploymentUriPath;
	
/*!
	\brief Returns the bundles /Contents/Resources/Deployments.plist dictionary
	
	The Deployments.plist should be included in the web app bundles Resources directory. This file provides information
	about the various deployment modes for the application. fmtool on the server uses these to generate httpd configuration
	settings for the applications.
 
	Structure
	Mode -> 
	    [configuration-name] ->
	        Root = The relative root of the web app, this can be used for multiple webapps per domain.
	        Port = The port the app runs on, must be unique on machine.
	        Host = The host name or ip (or regular expression)  for the domain
			Disabled = BOOL to disable an app.
		
 
	NOTE: This use to return the Info.plist (or Info-Mac.plist) user info dictionary and
	that was used for deployments. Now by defualy a Deployments.plist is used, however for legacy
	support the old scheme is still supported.
 */
+ (NSDictionary*)deploymentConfigDictionary;

/*!
	\brief	Called from a httpd connector or other httpd server object when a request is received.
	\param  req A WebRequest instance initalized from httpd HTTP request data.
	\return	An autoreleased WebResponse instance that wraps data that will get sent as a HTTP response.
*/
- (WebResponse*)handle:(WebRequest*)req;

/*!
	\brief The application's delegate if set.
 
	Application delegates are configured in the Info.plist with key <i>froth_app_delegate</i>. The value should
	be the class name of the delegate to use.
 
	Delegates are initalized and released for each request. Controllers can access delegates with the following.
	\code
	[self.application.delegate doSomethingSpecial];
	\endcode
 
	Likewise, templates can access delegates with.
	\code
	{{app.delegate.someWidgetOutput}}
	\endcode
*/
- (id)delegate;

@end
