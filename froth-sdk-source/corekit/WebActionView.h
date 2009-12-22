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
					Webviews, can optionally have a corresponding matching "<ClassName>.<extention>" file that contains html that can be parsed
					using the standard templating engine. Optionally subclasses can overide - (id)renderedOutput that can be used to return custom
					data.
					<br><br>

					For automatic loading to work, subclasses should be named,
					{Controller}{Action}View
 
					<br><br>
					The WebApplication controller automatically maps extentions to layouts when seting up the webview.
					The following dynamic rules apply to layouts.
					<br>1. if Content-Type = text/html || last-path-com has extention .html has extention (xml) extention = html
					<br>2. if Content-Type = text/xml  || last-path-com has extention xml extention = xml
					<br>3. if Content-Type = text/json || last-path-com has extention json extention = json
					<br>4. default with no extention, extention = html
					<br>5. all other path extentions are mapped to = extention property
					<br><br>
 
					Action views expose the following data to templates for using in template.
					<br><b>data</b> = The actual data returned by the controller (keyvalue object)
					<br><b>controller</b> = The controller for the request
					<br><b>request</b>	= The request object and thus the session via {{request.session....}}
					<br><b>app</b> = The main WebApplication object
					<br><b>view</b> = This object.
 */
@interface WebActionView : NSObject <MGTemplateEngineDelegate> {
	NSString* templateName;
	//NSDictionary* data;
	NSString* extention;
}
/*
	The extention for the view. By defualt this is "html", and corresponds to the <ClassName>.html template for this
	view.
 
	This is configured by the WebApplication open receiving a request. Or optionally be the WebActionController class to overide the 
	request's extention.
 
	For example.
	http://host/site/path/to/something.js
	
	Then this view would have the extention "js" and can act on it appropriatly.
 
	However, the WebActionController, could overide this by with the following call, before the method return.
	- (void)someAction:(WebRequest*)request {
		... do stuff with request ...
		self.view.extention = @"html";
		//self.view.template = @"NicerHtmlTemplate.ext";
		//self.view.layoutName = @"alternateLayout";
	}
 */
@property (nonatomic, retain) NSString* extention;

/*
	The template name used for this view. If not set, the defualt is <ClassName>Template.<extention>
*/
@property (nonatomic, retain) NSString* templateName;

/*
	Data for the view to display. The defualt structure is
	{ "session":SessionObject,"controller":"controller-name","request":WebRequest,"action":"actionName","ModelName":NSDictionary{...} }
 */
//@property (nonatomic, retain) NSDictionary* data;

// The defualt implementation searches the WebApp's bundle's resources for <MyClassName>.<extention>
- (NSData*)templateDataForController:(id)controller;

// Subclasses can overide this to customize the defualt parsing of data.
- (NSData*)processedTemplateData:(NSData*)data 
		  withControllerResponse:(id)object 
					 controller:(id)controller 
						 request:(WebRequest*)req 
					 application:(id)app;

/* 
	Subclasses that wish to provide a complete custom output from the data can overide this, all of the above methods are called
	from this method, so implementors need to take that into consideration.
 */
- (NSData*)displayWithData:(NSDictionary*)data 
				controller:(id)controller 
				   request:(WebRequest*)request 
			   application:(id)app;

@end
