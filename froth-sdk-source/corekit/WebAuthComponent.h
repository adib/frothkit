//
//  WebAuthComponent.h
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
#import "WebComponent.h"
#import "WebAuthModelProtocal.h"

#define TEMP_SITE_SALT @"awefa234f9384hf0a9wrfha9dhfasudfha98hca92384h39r8hfasdufha98hq39a48hfoweidfhakdsjbzxcvbzkalsdfasdf"

/*! \brief	Provides the optional "WebAuthComponent" interface to a webApp 
	\detail	The auth component provides applications with a complete user
				authentication system for both regular http and rest based authentications.
				
				The auth component provides controllers provides the /login and /signup and
				logout methods of the attached "user manager"
 
				The auth controller provides basic action control, any lower level control
				over specific data must be implemented by the controller itself. This is simple
				one the auth component is in place, as a component can use the req.session user
				object that represents the user information configured into the the auth component.
 
				Configureation of the auth component is made by the bundle's 
				AuthConfig.plist file. This file provides the component<->model interface
				between a identity source and the authenticator.
				
				The per/controller request configureation are as follows.
				"allowed":["action1", action2", action3...]
				These are used to specify which controller actions are allowed without login. 
 
				By default all controller actions are disallowed.
 
				The Auth component makes use of the Session value "user" and this is provided to
				controllers as the user object that represents the <Identity> for the auth component.
 
				The WebAuthComponent provide the implementations for -loginAction and logoutAction, note
				however that if the controller also implements these methods, then the controller's implementation
				will be used.
 
				Upon successful login, the WebauthComponent inserts a JSON representable nsdictionary of the User object
				into the session key "user". Controller's that modify the user, should update the user object as this insures
				that display information that uses the session works as needed.
 
				The WebAuthComponent can do two possible things if the authentication fails.
				1. Use a redirect and redirect the user to a seperate site, configured with
				config key="onFail" value:"redirect" key="onFailData" value:"path_to_redirect"
				2. Through a flash message to the user using the flash ability of controllers.
				config key="onFail" value:"flash" key="onFailData" value:"Optional error string"
 */
@interface WebAuthComponent : NSObject <WebComponent> {
}

+ (NSString*)hash:(NSString*)value withSalt:(NSString*)salt;

@end
