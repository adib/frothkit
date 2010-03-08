//
//  WebView.m
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

#import "WebActionView.h"

#import "Froth.h"

#import "AGRegexTemplateMatcher.h"


//Built In Temlating Markers and Filters
#import "WKValueComparisonFilters.h"
#import "WKFunctionMarkers.h"

static NSMutableDictionary* m_staticTemplateCache = nil;

@implementation WebActionView
@synthesize templateName, extention;

+ (void)initialize {
	/*
		Currently cocotron does not implement +initialize in a thread safe manner. In such casses static values
		as the on below never work. We need to do this differently.
	 */
	if(!m_staticTemplateCache) {
		NSLog(@"WebActionView: Action Template Memrory Cache Initialized");
		m_staticTemplateCache = [[NSMutableDictionary alloc] init];
	}
}

- (id)init {
	if(self = [super init]) {
	}
	return self;
}

- (void)dealloc {
	[templateName release];
	[extention release];
	[super dealloc];
}

- (void)prepareDefualtMarkersAndFiltersForTemplateEngine:(MGTemplateEngine*)engine {
	[engine loadFilter:[[[WKValueComparisonFilters alloc] init] autorelease]];
	[engine loadMarker:[[[WKFunctionMarkers alloc] initWithTemplateEngine:engine] autorelease]];
}

- (NSData*)templateDataForController:(id)controller {
	NSData* cachedTemplate = [m_staticTemplateCache objectForKey:self.templateName];
	//NSLog(@"cached template:%@", [[NSString alloc] initWithData:cachedTemplate encoding:NSUTF8StringEncoding]);
	if(!cachedTemplate) {
#ifdef __APPLE__
		NSBundle* bundle =		[NSBundle bundleForClass:[controller class]];
#else
		NSBundle* bundle =		[NSBundle mainBundle];
#endif
		if(!bundle) {
			froth_exception(@"ActionTemplateException", @"Unable to load bundle for action controller");
		}
		
//TODO: fix this dumb hack properly...
#ifdef __APPLE__
		if([templateName hasSuffix:@".(null)"]) 
			templateName = [[templateName stringByReplacingOccurrencesOfString:@".(null)" withString:@".html"] retain];
#else
		if([templateName hasSuffix:@".*nil*"])
			templateName = [[templateName stringByReplacingOccurrencesOfString:@".*nil*" withString:@".html"] retain];
#endif
			
		NSString* path =		[bundle pathForResource:templateName ofType:nil];
		cachedTemplate =		[NSData dataWithContentsOfFile:path];
		if(cachedTemplate) {
			[m_staticTemplateCache setObject:cachedTemplate forKey:templateName];
		} else {
			//Now try with .html as defualt
			path = [bundle pathForResource:[[templateName componentsSeparatedByString:@"."] objectAtIndex:0] ofType:@"html"];
			cachedTemplate = [NSData dataWithContentsOfFile:path];
			if(!cachedTemplate) {
				froth_exception(@"ActionTemplateException", @"Unable to find action template resource for name %@ at path %@", templateName, path);
			} else {
				[m_staticTemplateCache setObject:cachedTemplate forKey:templateName];
			}
		}
	}
	return cachedTemplate;
}

- (NSData*)processedTemplateData:(NSData*)data 
		  withControllerResponse:(id)object 
					 controller:(id)controller 
						 request:(WebRequest*)req 
					 application:(id)app {
	MGTemplateEngine * engine = [MGTemplateEngine templateEngine];
	//TODO: move this to a global configureation utility
	[self prepareDefualtMarkersAndFiltersForTemplateEngine:engine];

	[engine setDelegate:self];
	[engine setMatcher:[AGRegexTemplateMatcher matcherWithTemplateEngine:engine]];
	
	NSString* template = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	NSDictionary* variables = [NSDictionary dictionaryWithObjectsAndKeys:(object!=nil)?object:[NSNull null], @"data", 
							   controller, @"controller", 
							   req, @"request", 
							   app, @"app", 
							   self, @"view", nil];
	
	//TODO: Causeing crash with cf version.
	NSString* result = [engine processTemplate:template withVariables:variables];
	[template release];
	
	return [result dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSData*)displayWithData:(id)data 
				controller:(id)controller 
				   request:(WebRequest*)request 
			   application:(id)appData {
	NSData* template = [self templateDataForController:controller];
	if(template) {
		return [self processedTemplateData:template 
					withControllerResponse:data
								controller:controller
								   request:request
							   application:appData];
	}
	return nil;
}

#pragma mark -
#pragma mark Template Delegate

/*
	Cocotron is not generating setters?
 */

#ifndef __APPLE__
/*
- (void)setTemplateName:(NSString*)aName {
	if(templateName != aName) {
		[templateName release];
		templateName = nil;
		templateName = [aName retain];
	}
}

- (void)setExtention:(NSString*)aVal {
	if(extention != aVal) {
		[extention release];
		extention = nil;
		extention = [aVal retain];
	}
}
*/
#endif

@end
