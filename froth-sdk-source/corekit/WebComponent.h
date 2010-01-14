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
//	OTHER DEALINGS IN THE SOFTWARE.FTWARE OR THE USE OR
 //	OTHER DEALINGS IN THE SOFTWARE.
 
 
#import <Foundation/Foundation.h>
#import "WebActionController.h"
#import "WebRequest.h"
#import "WebResponse.h"

/*!
	\brief		Components provide the ability to share logic across a group of controllers/applications.
	
				Like all WebActiveControllers in Froth, components shared accross multiple user sessions and requests,
				an no instance valiables should be set based on a single session, all session info should be put into the 
				request's session object if it needs to be persisted.
 
				Froth includes the WebAuthComponent, as well as other components for simplifying the logic of
				development. See the api docs for all available components.
				- WebAuthComponent
 
				When a component is included with a controller, all methods of the component as described below 
				are called on the component. The component as also accessable from the controller for various processing
				purposes.
 
				Some components also require per-controller/request configuration. This is provided to the component
				with the method's withConfiguration:config dictionary. Note however that this may be nil under some situations, however
				it is typically up to the component's design to indicate that it needs configuration from the controller.
 
				Model object should not generally be used for a component. Their are times however, that a component will
				be given access to a model/object via the controller such as with the WebAuthComponent, however for best coding
				a components view on the controller's model object should be agnostic and not tied to a specific model.
*/
@protocol WebComponent

/*! 
	\brief		Called after the controller's -preProcessRequest:(WebRequest*)request, 
	
				This can be used for filtering requests before getting passed the controller.
				If this returns any value other then nil, then the controller is skiped in the
				processing cycle and the return from this is is processed by WebApplication as a response.
 
	\param		config
				A optional configuration dictionary supplied by the controller from -prepareComponentWithName: or NSNull
				if the WebActiveController does does not implement the method or returns nil.
 
	\return		Any of 
				- nil			[allows controller to continue processing using normal actions]
				- WebResponse	[returned directly without any processing]
				- NSString		[raw string returned to requestor]
				- Object		[accessable via kvo from template]
 */
- (id)preProcessRequest:(WebRequest*)request
		  forController:(id <WebActionController>)controller 
	 withConfiguration:(NSDictionary*)config;

/*!	
	\brief		Called after the controller's -postProcessResponse is called (if enabled).
	
				Provides the component another chance to modify the controller's response.
				This also called if -preProcessRequest returns an object, the response would
				be directly from that method.
 
				WebComponents that need to modify the layout for the view, or the template can do
				so in this method block. to substitute, just like in a controller's action, the 
				way to do it is 
 
				\code
				controller.view.template = @"AuthFailedTemplate";
				\endcode
  
	\param		response
				This could be nil, NSStrring, WebResponse or more typically a dataobject/array.
				This enables the component to modify the content if needed.

	\param		config
				A config dictionary supplied by the controller from -prepareComponentWithName: or NSNull
				if the control does does not implement the method, or returns nil from it.
 
	\return		The result can be used to overide the response. If no changes are mode, components
				can simply respond with the response object.
				\code
				- (id)postProcessResponse:(id)response fromRequest:(WebRequest*)req {
					return response;
				}
				\endcode

 */
- (id)postProcessResponse:(id)response 
			  fromRequest:(WebRequest*)request 
			 ofController:(id <WebActionController>)controller
		withConfiguration:(NSDictionary*)config;


@end


