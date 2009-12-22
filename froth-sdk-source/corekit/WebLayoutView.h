//
//  WebLayoutView.h
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

@class WebResponse;
@class WebRequest;
@class WebActionController;
@protocol WebActionController;


/*!
	\brief	Subclassable layout class for generating the layout for the request. Like actions, this can be overiden to customize.
				However unlike actions, unless this is subclassed and specified in the controller's init<Method>Action: method, then the
				defualt site specific layout is used. (this object.).
			
				The defualt implementation always looks for a Template file in the bundle named Layout.<extention>. Controllers can customize
				the Template file name, and to do so, must do it in the - <methodNAme>Action: method block, allong with the same for changeing
				the ACtion view's template file.
 
				The default layout view is cached for the life of the application. This provides faster loading as a round-trip to the
				data does not have to occur, only template parsing.
 
				Layout templates are provided with the following values.
				result = The actual string result from the action.
				controller = The controller that called the action
				req = The request object for the action
				app = The main application
				layout = This class.
				flash = a optional flash message sent by the controller with self.flash = @"a message to flash"
 */
@interface WebLayoutView : NSObject {
	NSString* templateName;
	NSMutableDictionary* m_cachedTemplates;
}

/*
	The template name used for this view. If not set, the defualt is Layout.<extention>
 */
@property (nonatomic, retain) NSString* templateName;

/*
	The defualt implementation attempts to first find a "template" file in the bundles resources, if not, then the defualt, else
	it returns nil.
 */
- (NSString*)templateStringForController:(id)controller;

/*! 
	\brief	Subclasses can overide this to provide custom data parsing of the templates. 
	\detail	The primary purpose of receiveing the templateData as NSData instead of NSString, as template subclasses
				may return binary data, in which case this layout template could provide an html wrapper for the data and
				return that as a WebResponse. 
				
				Such implementations would be cases where dynamic image data is generated based on the request. This provides
				powerful features for the Froth system.
 
				Subclasses would be responsible for calling -templateStringForController: as this is called from this classes
				implemention.
 */
- (WebResponse*)displayWithTemplateData:(NSData*)templateData 
						   forExtention:(NSString*)extention 
								request:(WebRequest*)request 
							 controller:(id <WebActionController>)controller
							application:(id)app;

@end
