//
//  WebApplication.m
//  Froth
//
//  Created by Allan Phillips on 23/02/09.
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

#import "WebApplication.h"
#import "froth.h"

#define kParamsUriRootKey		@"com.cocoa-web.uri-root"
#define kParamsUriDebugEnabled	@"com.cocoa-web.debug-enabled"
#define kWebAppBundleLocation	@"~/WebApps"

@implementation WebApplication

+ (NSString*)deploymentMode {
	static NSString* fDeploymentModeStr;
	if(fDeploymentModeStr == nil) {
		NSArray* comps = [[[NSBundle mainBundle] bundlePath] pathComponents];
		fDeploymentModeStr = [[comps objectAtIndex:comps.count-2] retain];
	}
	return fDeploymentModeStr;
}

+ (NSString*)deploymentUriPath {
	static NSString* fDeploymentUriPath;
	if(fDeploymentUriPath == nil) {
		NSDictionary* deploymentDictionary = [self deploymentConfigDictionary];
		if([[deploymentDictionary allKeys] containsObject:@"Modes"]) {
			NSString* path = [deploymentDictionary valueForKeyPath:froth_str(@"Modes.%@.Root", [self deploymentMode])];
			fDeploymentUriPath = [path retain];
		} else {
			NSString* deployPathKey = froth_str(@"froth_root_%@", [self deploymentMode]);
			NSString* path = [deploymentDictionary valueForKey:deployPathKey];
			fDeploymentUriPath = [path retain];
		}
	}
	return fDeploymentUriPath;
}

+ (NSDictionary*)deploymentConfigDictionary {
	static NSDictionary* fDeploymentConfigDictionary;
	if(fDeploymentConfigDictionary == nil) {
		NSString* modernConfPath = froth_str(@"%@/Contents/Resources/Deployments.plist", [[NSBundle mainBundle] bundlePath]);
		fDeploymentConfigDictionary = [NSDictionary dictionaryWithContentsOfFile:modernConfPath];
		
		//Legacy support
		if(!fDeploymentConfigDictionary) {
			fDeploymentConfigDictionary = [[[NSBundle mainBundle] infoDictionary] retain];
		}
	}
	return fDeploymentConfigDictionary;
}

- (id)init {
	if(self = [super init]) {
		m_app_path = [[NSBundle mainBundle] bundlePath];
	
		m_cachedWebActionControllerClasses = [[NSMutableArray array] retain];
		m_componentInstances = [[NSMutableDictionary dictionary] retain];
		
		//Load up our embeded bundle
		[[NSBundle mainBundle] load];
		
		//Check for an application delegate
		NSString* delegateClassName = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"froth_app_delegate"];
		if(delegateClassName) {
			m_delegateClass = NSClassFromString(delegateClassName);
		}
	}
	return self;
}

- (void)dealloc {
	[m_defualtLayoutView release], m_defualtLayoutView = nil;
	[m_defualtActionView release], m_defualtActionView = nil;
	[m_app_path release], m_app_path = nil;
	[m_cachedWebActionControllerClasses release], m_cachedWebActionControllerClasses = nil;
	[m_componentInstances release], m_componentInstances = nil;
	[delegate release], delegate = nil;
	
	[super dealloc];
}

#pragma mark -
#pragma mark Internal Request Processing

/*
	Amazon Targets have a strange bug where the
	controller name gets capitalized start & end characters! thats a bug probably in Foundation.framework.
*/
- (NSString*)_controllerNameForRequest:(WebRequest*)req {
	NSString* controllerName = req.controller;
	if(controllerName) {
		NSArray* parts = [controllerName componentsSeparatedByString:@"-"];
		if(parts.count<2)
			parts = [controllerName componentsSeparatedByString:@"_"];
		
		if(parts.count>1) {
			NSMutableString* contName = [NSMutableString string];
			for(NSString* part in parts) {
				[contName appendString:[part firstLetterCaptialized]];
			}
			return contName;
		}
		return [controllerName firstLetterCaptialized];
	}
	return nil;
}

- (id <WebActionController>)_controllerInstanceForRequest:(WebRequest*)wr {
	NSString* controllerName = [self _controllerNameForRequest:wr];
	NSString* className = [NSString stringWithFormat:@"WA%@Controller", controllerName];
	
	NSLog(@"WebApplication: Possible WebActionController [%@] for controller name [%@]", className, controllerName);
	
	Class theClass = NSClassFromString(className);
	
	//Try a streightAccross class id MyClass
	if(!theClass) theClass = NSClassFromString(controllerName);
	
	//Maybe its for internal testing class
	if(!theClass && [controllerName isEqualToString:@"Frothtests"]) {
		NSLog(@"WebApplication: Using Froth Testing Controller");
		theClass = NSClassFromString(@"FrothTestingController");
	}
	
	//Make sure it conforms to the WebActionController
	if(theClass && [theClass conformsToProtocol:@protocol(WebActionController)]) {
		id <WebActionController> controller = [[theClass alloc] init];
		controller.application = self;
		
		return controller;
	}
	
	NSLog(@"WebApplication: [[ERROR]] returning nil controller.");
	
	return nil;
}

- (WebActionView*)_defaultActionView {
	//if(!m_defualtActionView) {
		return /*m_defualtActionView =*/ [[[WebActionView alloc] init] autorelease];
	//}
	//return m_defualtActionView;
}

- (WebActionView*)_webViewForName:(NSString*)className {
	Class theClass = NSClassFromString(className);
	
	//Try a streightAccross class id MyClass
	
	//Make sure it conforms to the WebActionController
	if(theClass && [theClass isSubclassOfClass:[WebActionView class]]) {
		WebActionView* view = [[theClass alloc] init];
		return view;
	} else {
		return [self _defaultActionView];
	}
	
	NSLog(@"WebApplication+ returning nil view.");
	
	return nil;
}

- (SEL)_selectorForWebRequest:(WebRequest*)request controller:(id)controller {
	SEL actionSelector = nil;
	
	NSString* action = request.action;
		
	//Allow controllers to replace action names with custom selectors
	if([controller respondsToSelector:@selector(selectorForActionName:)]) {
		actionSelector = [controller selectorForActionName:action];
	}
	
	//Convert the action name into a controller selector if controller responds
	if(!actionSelector) {		
		if(action) {
			NSString* actionName = [NSString stringWithFormat:@"%@Action:", action];
			SEL possibleSelector = NSSelectorFromString(actionName);
			
			if([controller respondsToSelector:possibleSelector]) {
				actionSelector = possibleSelector;
			}
		}
	}
	
	//Handle defualts such as -index, -object, -create, -update and -delete for CRUD
	NSString* rmethod = request.method;
	if(!actionSelector && ([rmethod isEqualToString:@"GET"] || [rmethod isEqualToString:@"HEAD"])) {
		if(action) {
			actionSelector = @selector(object:);
		} else {
			actionSelector = @selector(index:);
		}
	}
	
	if(!actionSelector && ([rmethod isEqualToString:@"POST"] || [rmethod isEqualToString:@"PUT"])) {
		if(action) {	//Not really an action but a index value for rest style
			actionSelector = @selector(update:);
		} else {
			actionSelector = @selector(create:);
		}
	}
	
	if(!actionSelector && [rmethod isEqualToString:@"DELETE"]) {
		actionSelector = @selector(delete:);
	}
	
	if(!actionSelector) {
		actionSelector = @selector(unhandledAction:);
	}
	
	return actionSelector;
}

- (WebResponse*)_responseForRequest:(WebRequest*)request withController:(id <WebActionController>)controller {
	
	/*
		Get the components used if implemented
		Request Processing stage 1.
	 */
	NSMutableArray* components = nil;
	NSMutableArray* componentConfigurations = nil;
	if([controller respondsToSelector:@selector(components)]) {
		NSArray* componentNames = [controller components];
		components = [NSMutableArray array];
		componentConfigurations = [NSMutableArray array];
		
		for(NSString* compName in componentNames){
			id nInstance = [m_componentInstances objectForKey:compName];
			if(!nInstance) {
				Class nInstClass = NSClassFromString(compName);
				if(nInstClass && [nInstClass conformsToProtocol:@protocol(WebComponent)]) {
					nInstance = [[nInstClass alloc] init];
				}
				
				if(!nInstance) NSLog(@"WebApplication: Error 234 - Cannot find component:%@ for controller:%@", compName, request.controller);
				[m_componentInstances setObject:nInstance forKey:compName];
			}
			
			//Allow the controller to prepare the component
			NSDictionary* compConfig = nil;
			if([controller respondsToSelector:@selector(prepareComponentWithName:)])
				compConfig = [controller prepareComponentWithName:compName];
			if(compConfig)
				[componentConfigurations addObject:compConfig];
			else 
				[componentConfigurations addObject:[NSNull null]];
			
			[components addObject:nInstance];
		}
	}
		
	//The offical parsed response
	WebResponse * response = nil;
	
	//The response of the action (either, NSString, WebResponse, object, or nil
	id actionResponse = nil; 
	
	//Pre-process request attempt with components, skips if components is nil.
	int i = 0;
	for(id <WebComponent> ncomp in components) {
		response = [ncomp preProcessRequest:request 
							  forController:controller 
						  withConfiguration:[componentConfigurations objectAtIndex:i]];
		if(response) {
			//Becouse we handle the response, we make the controller use the defualt action view as thats all thats
			//provided to the component. Of course it can use its own by simply replacing the controllers.
			actionResponse = response;
		}
		i++;
	}
	
	if([controller respondsToSelector:@selector(preProcessRequest:)] && !actionResponse)
		[controller preProcessRequest:request];
		
	//Fix this for component overides of names
	SEL selector = [self _selectorForWebRequest:request controller:controller];
	
	NSLog(@"WebApplication: Possible ObjC method for action [%@]", NSStringFromSelector(selector));

	//Finally do the action
	//Initialize, setup view, then performSelector..
	NSString* actionString = NSStringFromSelector(selector);
	NSString* initAction = [NSString stringWithFormat:@"init%@", [actionString capitalizedString]];
	SEL initActionSel = NSSelectorFromString(initAction);
	//NSLog(@"possible login action:%@", NSStringFromSelector(initActionSel));
	/*
		If we already have an action response then that means a component
		overode the controller, theirfor we should keep the name sent
		as the component properly handled it.
	 */
	if(actionResponse) {
		actionString = request.action;
	}
	
	if([controller respondsToSelector:initActionSel]) {
		[controller performSelector:initActionSel withObject:request];
	} else {
		/*
			We need to initialize the view ourself.
		 */
		NSString* full = [NSString stringWithFormat:@"%@%@View", 
								 [[self _controllerNameForRequest:request] firstLetterCaptialized],
								[[actionString stringByReplacingOccurrencesOfString:@":" withString:@""] firstLetterCaptialized]];
	
		//remove the "action" part
		NSString* webViewClassName = [full stringByReplacingOccurrencesOfString:@"Action" withString:@""];
		webViewClassName = [webViewClassName stringByReplacingOccurrencesOfString:@"action" withString:@""];
		
		NSLog(@"WebApplication: Possible WebActionView Class Name [%@]", webViewClassName);
	
		WebActionView* actionView = [self _webViewForName:webViewClassName];
		if(actionView) {
			//Setup the view's templating structure.
			NSString* extention = request.extension;
			if(!extention) {
				NSString* contentType = request.contentType;
				if(!contentType || [contentType isEqualToString:@"text/html"]) {
					extention = @"html";
				} else if([contentType isEqualToString:@"text/xml"]) {
					extention = @"xml";
				} else if([contentType isEqualToString:@"text/json"]) {
					extention = @"json";
				}
			}
		
			actionView.extention	= extention;
			actionView.templateName = [NSString stringWithFormat:@"%@.%@", webViewClassName, extention];
			NSLog(@"WebApplication: Possible WebActionView Template [%@]", actionView.templateName);
			
			//The controller has a chance to overide this information
			controller.view = actionView;
			//[actionView release];
		}
	}
	
	//Setup the controller's layout view if not configured (This may have been done in -init<Action>Action)
	//Note that this may not be used if the controller returns a WebResponse instead of another object.
	if(!controller.layout) {
		// The defualt application layout view is cached for the life of the application.
		/*if(!m_defualtLayoutView) {
			NSLog(@"initializeing new m_defualt layout view");
			m_defualtLayoutView = [[[WebLayoutView alloc] init] retain];
		}
		m_defualtLayoutView.templateName = [NSString stringWithFormat:@"Layout.%@", controller.view.extention];
		controller.layout = m_defualtLayoutView;*/
		
		/* 
			We cannot use the WebApp cached becouse we will need one/per thread. And currently this is the only way
			to do this. We could over perform and init on each thread to provide a true multi threaded approach?
		 */
		WebLayoutView* l_layout_view = [[WebLayoutView alloc] init];
		l_layout_view.templateName = [NSString stringWithFormat:@"Layout.%@", controller.view.extention];
		NSLog(@"WebApplication: Possible Layout Template [%@]", l_layout_view.templateName);
		controller.layout = l_layout_view;
		[l_layout_view release];
	}
	
	BOOL responseFromComponent = NO;
	if(!actionResponse)
		actionResponse = [controller performSelector:selector withObject:request];
	else
		responseFromComponent = YES;

	if([controller respondsToSelector:@selector(postProcessResponse:fromRequest:)] && !responseFromComponent)
		actionResponse = [controller postProcessResponse:actionResponse fromRequest:request];
	
	//Now provide any controller components the ability to post process the response.
	//The any of the components my substatue the layout or template for the action, the can do it via the controller.
	i = 0;
	for(id <WebComponent> nComp in components) {
		actionResponse = [nComp postProcessResponse:actionResponse 
										fromRequest:request 
									   ofController:controller
								  withConfiguration:[componentConfigurations objectAtIndex:i]];
		i++;
	}

	if([actionResponse isKindOfClass:[WebResponse class]]) {
		/*
			The controller wishes to generate the WebResponse directly without a mvc appoach.
		 */
		response = actionResponse;
	} else if([actionResponse isKindOfClass:[NSString class]]) {
		/* 
			Super conveince ability for a controller to return a streight nsstring for display as html
		 */
		WebResponse* stringHtmlResponse = [WebResponse htmlResponse];
		stringHtmlResponse.bodyString = actionResponse;
		response = stringHtmlResponse;
	} else {

		/* 
		 The response is data, and should be handled by the controller's view.
		 */		
		NSData* data = [controller.view displayWithData:actionResponse 
						controller:controller
						request:request
						application:self];
		
		response = [controller.layout displayWithTemplateData:data 
												 forExtention:controller.view.extention
													  request:request
												   controller:controller
												  application:self];
	}

	//Now generate a x-session-froth cookie if needed, this is generated from the request.session so we can use
	//any user values set in the session, for api requests controllers must supply the session key in an alternative way.
	if(![request valueForCookie:@"x-froth-session"]) {
		NSLog(@"WebApplication: Generating new x-froth-session coookie for request :%@", request.session.guid);
		[response setCookieValue:[request.session.guid stringByReplacingOccurrencesOfString:@"\000" withString:@""]	//Not sure yet why the guid is getting padded with \000
						  forKey:@"x-froth-session" 
						  expires:[[NSDate date] addTimeInterval:172800] //2 days //TODO: Make this configurable via webApp configuration dictionary in bundle
						  secure:NO
						  domain:froth_str(@".%@", [request valueForHeader:@"HTTP_HOST"])
						  path:@"/"];
		//TODO: only set the cookie for the webApp root as defined in webApp properties
	}

	return response;
}

#pragma mark -
#pragma mark Error Responses

- (WebResponse*)_notFoundResponseForRequest:(WebRequest*)webReq {

	if(!webReq.controller) {
		return [WebResponse redirectResponseWithUrl:[NSString stringWithFormat:@"http://%@/home", [webReq domain]]];
	}
	
	if([webReq.controller isEqualToString:@"exe"]) {
		return [self performSelector:@selector(internalEXEHandle:) withObject:webReq];
	}
	
	//No controller found, need to send off a 404. error.
	WebResponse *rs = [WebResponse responseWithCode:404];
	[rs setHeader:@"text/html; charset=UTF-8" forKey:@"Content-Type"];
	
	NSMutableString *s = [[NSMutableString alloc] init];
	[s appendFormat:@"<html><head><title>No page found: http://%@%@</title></head><body>", [webReq domain], [webReq url]];
	[s appendFormat:@"<h1>404 error: File not found - '%@'</h1>", [webReq url]];
	[s appendFormat:@"<p>Did you mean to visit <a href='http://%@'>http://%@</a>?</p>", [webReq domain], [webReq domain]];
	[s appendString:@"<p><i>This Site is powered by <a href='http://www.frothkit.org'>Froth</a></i></p></body></html>"];
	rs.bodyString = [s autorelease];
	return rs;
}

#pragma mark -
#pragma mark As WebApplicationProtocal

//Called internally for each request.
- (WebResponse*)handle:(WebRequest*)req {
	NSLog(@"WebApplication: Handling server request [%@]", req);
	
	if(m_delegateClass)
		delegate = [[m_delegateClass alloc] init];
	
	WebResponse* res = nil;
	
	id <WebActionController> controller = [self _controllerInstanceForRequest:req];
	if(controller) {
		res = [self _responseForRequest:req withController:controller];
	} else {
		res = [self _notFoundResponseForRequest:req];
	}
	
	//Clean up
	[delegate release], delegate = nil;
	[controller release];
	
	return res;
}

#pragma mark -
#pragma mark Internal Debug Methods

/*
	This are handled by the -_notFoundResponseForRequest: method based on a controller name of /exe
 */
- (id)internalEXEHandle:(WebRequest*)req {
	/*if([req.action isEqualToString:@"timezones"]) {
		NSMutableString* tz = [NSMutableString string];
		[tz appendString:@"<h1>System TimeZone Database Names</h1>"];
		[tz appendString:@"<ul>"];
		NSArray* tzArr = [NSTimeZone knownTimeZoneNames];
		for(NSString* tZS in tzArr) {
			NSTimeZone* next = [NSTimeZone timeZoneWithName:tZS];
			[tz appendFormat:@"<li>%@ - %@ - %i", tZS, [next abbreviation], [next secondsFromGMT]];
		}
		[tz appendString:@"</ul>"];
		return [WebResponse htmlResponseWithBody:tz];
	} else if([req.action isEqualToString:@"tzabbreviations"]) {
		return [WebResponse htmlResponseWithBody:[[NSTimeZone abbreviationDictionary] description]];
	} else if([req.action isEqualToString:@"exp-test"]) {
		froth_exception(@"TestException", @"Simple message:%@", [req description]);
	}*/
	return [WebResponse notFoundResponse];
}

#pragma mark -
#pragma mark Application Delegation

- (id)delegate {
	return delegate;
}

@end
