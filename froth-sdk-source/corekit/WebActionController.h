//
//  WebActionController.h
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
@class WebRequest;
@class WebResponse;
@class WebActionView;
@class WebLayoutView;
@class WebApplication;
@protocol WebComponent;


/*!
	\brief	Action controller protocal, typically a subclass WebActiveController should be used instead.
			
			<h3>Memory Management</h3>
			Action controllers are the heart of a Cocoa Web App, they are considered short lived
			objects and should implement proper Cocoa memory management techneques 
			(<a href="http://developer.apple.com/mac/library/documentation/cocoa/Conceptual/MemoryMgmt/MemoryMgmt.html">See here</a>). 
			They only live for the life span of the request.
			
			<h3>Nominclature of Subclasses</h3>
			Class names must have the format <i>WA<ControllerName>Controller</i>
			
			<i>Example</i><br>
			\code
			http://example.com/[path/to/webapp]/my_blog/some_great_blog
			\endcode
			Gets conditionally mapped to WAMyBlogController's method...
			\code
			-(id)someGreatBlog:(WARequest*)request 
			\endcode
			
			If this is not implemented, the controller has a change to pick up the method with it method...
			\code
			-(id)defualt:(WebRequest*)request
			\endcode
			
			Complete routing rules are detailed below.<br>
			<i>Future work will be done to free subclasses from the strict nameing conventions</i>
		
			<h3>Request Routing</h3>
			A) {{method-name}} automatically maps to - (id)<methodName>Action:(WebRequest*)wr; if implemented or <br>
			A.1) -(id)object:(WebRequest*)wr if implemented or <br>
			A.2) -(id)defualt:(WebRequest*)wr if implemented <br>
			<br><br>
			<i>CRUD Routing</i>
			B) No Action Method	(GET)				 maps to -(id)index:(WebRequest*)wr; <br>
								(GET)/{v}			 maps to -(id)object:(WebRequest*)wr; <br>
			C) No Action Method (POST/POST)			 maps to -(id)create:(WebRequest*)wr; /-update:... <br>
			E) No Action Method (DELETE)			 maps to -(id)delete:(WebRequest*)wr; <br>

			<br><br>
			The flow of events for a WebRequest object is as such. <br>
			1. WebApplicationController receives a WebRequest. <br>
			2. if controller provides "components" array, call, -preProcessRequest: forController: on each continuing if result is not nil. <br>
			2. WebApplicationController calls - (void)preProcessRequest:(WebRequest*)request if implemented. <br>
			3. WebApplicationController calls - (SEL)selectorForActionName:(NSString*)name if implemented, and uses it as <ActionName> <br>
			4. WebApplicationController insures that <ActionName> is implemented. <br>
			5. WebApplicationController calls - (void)init<ActionName>Action:(WebRequest*)request if implemented <br>
				<br><br>
				<i>The WebApplicationController, should initialize and setup the controller's views, and other properties
				here if a custom (not defualt view) is to be used. Initializeing this method will cause the WebApplicationController
				to not prepare any defualts based on the request.</i>
				<br><br>
			6. Else a class with name <ActionName><ControllerName>View is looked up and initialized if found. <br>
			7. WebApplicationController calls - (id)<actionName>Action:(WebRequest*)request <br>
			8. If the above call returns a WebResponse object, then it is rendered, else... <br>
			9. A WebResponse is returned from [controller.view displayWithData:(above response)] //typically a NSDictionary <br>
			10. WebApplication calls - (void)postProcessResponse:(FOWResponse*)response fromRequest:(WebRequest*)request on controller if implemented <br>
			11. if controller provides "components" array, call -postPRocessResponse for each while result is true (false returns a notFound response) <br>
			
 //TODO: fix documentation for WebLayoutViews

				1. WebViews handleing rendering in the following flow.
				- (WebResponse*)displayWithData:(NSDictionary*)data is called.
				//Subclasses can overide this to provide complete custom rendering.
				2. The defualt implementation finds a <ClassName>Template.<extention> template file using 
				- (NSData*)templateData;
				3. The defualt implementation then parses the template with
				- (NSData*)processedTemplateData:(NSData*)templateData;
				4. The defualt implementation then converts the template data into a WebResponse with
				- (WebResponse*)responseForProcessedTemplate:(NSData*)template;
 */
@protocol WebActionController <NSObject>

@property (nonatomic, assign) WebApplication* application;
@property (nonatomic, retain) WebActionView* view;

/*!
	If this returns nil, the the base layout view is returned. Controllers that with to provide custom layout controllers
	can subclass WebLayoutView and provide that object in the - init<Action>Action method
 */
@property (nonatomic, retain) WebLayoutView* layout;

@optional
/*!
	\brief	An ordered array of component names that are inserted into the request graph for processing.
	\detail	See WebComponent header for implementation details.
 */
 - (NSArray*)components;
 
/*!
	\brief	Gives the controller a per/request ability to set component properties.
	\detail	This gets called prior to -preProcessRequest, and can be used for
				component variable configureation specific to a given controller
				
				IE the Auth component uses this to allow the controller to dynamically set the
				allowed/deny properites for actions outside of its global AuthComponent.plist
 */
- (NSDictionary*)prepareComponentWithName:(NSString*)componentName;

/*
	Optional
	Useing this an action controller can use alternate action methods then the typical built in
	auto method-selecto resolving. This gets called first (if implemented) if no result, then
	a regular selector method is called
 */
- (SEL)selectorForActionName:(NSString*)name;
- (void)preProcessRequest:(WebRequest*)request;

/*
	Optional
	Controllers can use this to post process the response before it hits the renderer.
	The response could be, nil, WebResponse, NSString or more typically data for the
	rendered to used in rendering layout.
 
	Controllers can return a new response if they with to modify the data.
 */
- (id)postProcessResponse:(id)response fromRequest:(WebRequest*)request;

//- (id)defualtAction:(WebRequest*)request;

@end
