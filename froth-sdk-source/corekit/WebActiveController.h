//
//  WebActiveController.h
//  Froth
//
//  Created by Allan Phillips on 14/07/09.
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
#import "WebActionController.h"
#import "WebActionView.h"
#import "WebLayoutView.h"

/*!	
	\brief	Provides a abstract base class for direct crud and dry conventions using data model connectors. 
	\detail	For insured memory management design and webApp efficiency, new webApp action controllers
				should subclass this class instead of implement the WebActionController protocal
 */
@interface WebActiveController : NSObject <WebActionController> {
	WebActionView* view;
	WebLayoutView* layout;
	NSString* flash;
}
@property (nonatomic, retain) WebActionView* view;
@property (nonatomic, retain) WebLayoutView* layout;

/*!
	\brief Set this in a controller action method to in combination with templating variable -flash
	
	The master layout or view template typically uses the flash for display purposes. The
	build in method for it is {% if flash %} {{flash}} {% /if %} and it will only show if the flash is availible.
 */
@property (nonatomic, retain) NSString* flash;

/*!
	The defualt implementation is the same name as the controller, minus the (s)
	Subclasses can overide this to provide custom model class names
 
	TODO: Not Implemented
 */
- (NSString*)modelClassName;

/*
	Subclasses should implement the following methods to support pre action setup (See WebActionController)
	- (void)init<ActionName>Action:(WebRequest*)request;
 
	Then for each action
	- (id)<actionName>Action:(WebRequest*)request;
 
	The return value can be on of three options.
	A. KVO accessable dictionary for access by view templates. (ie {{ data.key.path }} )
	B. NSString for direct rendering as a html output.
	C. WebResponse setup with output data/body content.
 
	Other optional methods
	- (SEL)selectorForActionName:(NSString*)name;
	Details: Dynamically replace action names with new selector
 
	- (void)preProcessRequest:(WebRequest*)request;
	- (void)postProcessResponse:(WebResponse*)response fromRequest:(WebRequest*)request
	- (id)defualtAction:(WebRequest*)request;
 */

/*! \brief Method for a GET to ./controller */
- (id)index:(WebRequest*)wr;

/*! \brief Method for a GET to ./controller/uuid */
- (id)object:(WebRequest*)wr;

/*! \brief Method for a PUT/POST to ./controller & body of xml | json | form-encoded (use content-type for def) */
- (id)create:(WebRequest*)wr;

/*! \brief Method for a PUT/POST to ./controller/[uid] & body of xml | json | form-encoded */
- (id)update:(WebRequest*)wr;

/*! \brief Method for a DELETE to ./controller/[uid] */
- (id)delete:(WebRequest*)wr;

@end
