//
//  WebActiveController.m
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

#import "WebActiveController.h"


@implementation WebActiveController

- (void)setFlash:(NSString*)val {
	if(flash != val) {
		[flash release], flash = nil;
		flash = [val retain];
	}
}

- (NSString*)flash {
	return flash;
}

- (void)setView:(WebActionView*)val {
	if(view != val) {
		[view release], view = nil;
		view = [val retain];
	}
}

- (WebActionView*)view {
	return view;
}

- (void)setLayout:(WebLayoutView*)val {
	if(layout != val) {
		[layout release], layout = nil;
		layout = [val retain];
	}
}

- (WebLayoutView*)layout {
	return layout;
}
 
- (void)setApplication:(WebApplication*)app {
	application = app;
}

- (WebApplication*)application {
	return application;
}

- (void)setPageTitle:(NSString*)val {
	if(pageTitle != val) {
		[pageTitle release];
		pageTitle = [val retain];
	}
}

- (NSString*)pageTitle {
	return pageTitle;
}

- (NSString*)modelClassName {
	return nil;
}

- (void)dealloc {
	[view release];
	[layout release];
	[flash release];
	[pageTitle release];
	[super dealloc];
}

/*! \brief Method for a GET to ./controller */
- (id)index:(WebRequest*)wr {
	return [NSDictionary dictionary];
}

/*! \brief Method for a GET to ./controller/uuid */
- (id)object:(WebRequest*)wr {
	return [NSDictionary dictionary];
}

/*! \brief Method for a PUT/POST to ./controller & body of xml | json | form-encoded (use content-type for def) */
- (id)create:(WebRequest*)wr {
	return [WebResponse okResponse];
}

/*! \brief Method for a PUT/POST to ./controller/[uid] & body of xml | json | form-encoded */
- (id)update:(WebRequest*)wr {
	return [WebResponse okResponse];
}

/*! \brief Method for a DELETE to ./controller/[uid] */
- (id)delete:(WebRequest*)wr {
	return [WebResponse okResponse];
}

@end
