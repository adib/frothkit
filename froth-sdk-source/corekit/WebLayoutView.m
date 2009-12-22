//
//  WebLayoutView.m
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

#import "WebLayoutView.h"

#import "froth.h"

#import "AGRegexTemplateMatcher.h"

//Built In Temlating Markers and Filters
#import "WKValueComparisonFilters.h"
#import "WKFunctionMarkers.h"

@implementation WebLayoutView
@synthesize templateName;

- (id)init {
	if(self = [super init]) {
		m_cachedTemplates = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (NSString*)templateStringForController:(id)controller {
	NSString* cachedTemplate = [m_cachedTemplates objectForKey:self.templateName];
	if(!cachedTemplate) {
#ifndef __APPLE__
		NSBundle* bundle = [NSBundle mainBundle];
#else
		NSBundle* bundle =	[NSBundle bundleForClass:[controller class]];
#endif
		if(!bundle) {
			froth_exception(@"LayoutViewTemplateException", @"Unable to load bundle for action controller");
		}
		
		if([templateName hasSuffix:@".(null)"]) 
			templateName = [[templateName stringByReplacingOccurrencesOfString:@".(null)" withString:@".html"] retain];
		NSString* path =	[bundle pathForResource:self.templateName ofType:nil];
		
		//NSLog(@"path for layout resource:%@", path);
		NSString* objectData = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
		if(objectData) {
			cachedTemplate = objectData;
		} else {
			froth_exception(@"LayoutViewTemplateException", @"Unable to find layout template resource for name %@", templateName);
		}
		//TODO: temp remove cahcing so we can do live template updates
		//[m_cachedTemplates setObject:objectData forKey:self.templateName];
	}
	return cachedTemplate;
}

- (void)prepareDefualtMarkersAndFiltersForTemplateEngine:(MGTemplateEngine*)engine {
	[engine loadFilter:[[[WKValueComparisonFilters alloc] init] autorelease]];
	[engine loadMarker:[[[WKFunctionMarkers alloc] initWithTemplateEngine:engine] autorelease]];
}

//We use strings as, a custom actionview could return binary images or data by overideing  -displayWithTemplateData....
- (NSString*)processedActionResultString:(NSString*)actionResult 
							controller:(id)controller 
							   request:(WebRequest*)req 
						   application:(id)app {
	MGTemplateEngine * engine = [MGTemplateEngine templateEngine];
	//TODO: move this to a global configureation utility
	[self prepareDefualtMarkersAndFiltersForTemplateEngine:engine];
	
	[engine setDelegate:self];
	[engine setMatcher:[AGRegexTemplateMatcher matcherWithTemplateEngine:engine]];
	
	NSString* template = [self templateStringForController:controller];
	NSDictionary* variables = [NSDictionary dictionaryWithObjectsAndKeys:
							   actionResult, @"TemplateResult",
							   controller, @"controller", 
							   req, @"request", 
							   app, @"app", 
							   self, @"layout", 
							   ([controller flash])?[controller flash]:@"", @"flash", 
							   nil];
	
	NSString* result = [engine processTemplate:template withVariables:variables];	
	return result;
}

- (WebResponse*)displayWithTemplateData:(NSData*)templateData 
						   forExtention:(NSString*)extention 
								request:(WebRequest*)request 
							 controller:(id <WebActionController>)controller
							application:(id)app {
	NSString* actionResults =	[[NSString alloc] initWithData:templateData encoding:NSUTF8StringEncoding];
	//return [WebResponse htmlResponseWithBody:actionResults];
	NSString* resBody = [self processedActionResultString:actionResults controller:controller request:request application:app];
	[actionResults release];
	return [WebResponse htmlResponseWithBody:resBody];
}

- (void)dealloc {
	[m_cachedTemplates release];
	[templateName release];
	[super dealloc];
}

@end
