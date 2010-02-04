//
//  WebView.h
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
#import "WebResponse.h"
#import "WebRequest.h"

#import "MGTemplateEngine.h"

/*! 
	\brief		Represents a webview that is used to render content for a request. Content can be html, js, or anything. Even Images 
	
					Subclasses should implement the render method for rendering content. The content is rendered within a Layout html file.
					Webviews, can optionally have a corresponding matching "[ClassName].[ext]" file that contains html that can be parsed
					using the standard templating engine. Optionally subclasses can overide - displayWithData:controller:request:application:
					that could be used to return custom data.
 
					The WebApplication instance automatically maps uri extentions to appropriate views templates. The following 
					rules apply to layouts.
					- If Content-Type = text/html OR last-path-com has extention .html then, extention is html
					- If Content-Type = text/xml  OR last-path-com has extention xml then, extention is xml
					- If Content-Type = text/json OR last-path-com has extention json then, extention is json
					- If default with no extention then, extention is html
					- All other uri extentions are mapped directly to appropriate template extention.
 
					Action views expose the following data to templates for using in template.
					- data The actual data returned by the controller (keyvalue object)
					- controller The controller for the request
					- request The request object and thus the session via {{request.session....}}
					- app The main WebApplication object
					- view This object.
 
					Example template, for an array of objects with property -name returned from a WebActiveController instance action.
					\code
					- (id)peopleAction:(WebRequest*)req {
						//Set the title of the rendered page
						self.pageTitle = @"My People";
				
						//Example model object, typically these would be fetched from a data source.
						Person* p1 = [Person personWithName:@"John"]; 
						Person* p2 = [Person personWithName:@"Fred"];
						Person* p3 = [Person personWithName:@"Jimmy"];
						return [NSArray arrayWithObjects:p1, p2, p3, nil];
					}
					\endcode
 
					The template, accessable via http://example.com/controller_name/people
					\code
					<html>
						<title>{{controller.pageTitle}}</title>
						<body>
						<h1>Total People {% data.@count %}</h1>
						{% for person in data %}
							{% comment %}
								The value of data is anything returned from 
								the action method, (unless its a NSString or WebResponse)
							{% /comment %}
							<div class='person'>
								{% person.name %}
							</div>
						{% /for %}
					</html>
					\endcode
 */
@interface WebActionView : NSObject <MGTemplateEngineDelegate> {
	NSString* templateName;
	//NSDictionary* data;
	NSString* extention;
}
/*!
	\brief The extention for the view. By defualt this is "html", and corresponds to the [ClassName].html template for this view.
 
	This is configured by the WebApplication open receiving a request. Or optionally be the WebActionController class to overide the 
	request's extention.
 
	For example:
	http://example.com/site/path/to/something.js
	
	Then this view would have the extention "js" and can act on it appropriatly.
 
	The WebActionController, could overide this by with the following call, before the method returns.
	\code
	- (void)someAction:(WebRequest*)request {
		//do something special
		
		self.view.extention = @"html";
 
		//self.view.template = @"NicerHtmlTemplate.ext";
		//self.view.layoutName = @"alternateLayout";
		
		return nil; //some data
	}
	\endcode
 */
@property (nonatomic, retain) NSString* extention;

/*!
	\brief The template name used for this view. If not set, the defualt is <ClassName>Template.<extention>
*/
@property (nonatomic, retain) NSString* templateName;

/*! 
	\brief The defualt implementation searches the WebApp's bundle's resources for [MyClassName].[extention]
	\param controller A WebActionController implementing instance.
*/
- (NSData*)templateDataForController:(id)controller;

/*!
	\brief Subclasses can overide this to customize the defualt parsing of data.
 */
- (NSData*)processedTemplateData:(NSData*)data 
		  withControllerResponse:(id)object 
					 controller:(id)controller 
						 request:(WebRequest*)req 
					 application:(id)app;

/*!
	\brief Subclasses that wish to provide a complete custom output from the data can overide this, all of the above methods are called
			from this method, so implementors need to take that into consideration.
 */
- (NSData*)displayWithData:(id)data 
				controller:(id)controller 
				   request:(WebRequest*)request 
			   application:(id)app;

@end
