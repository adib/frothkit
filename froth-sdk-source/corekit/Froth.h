//
//
//  Froth.h
//  Froth
//
//	 Created by Allan Phillips on 24/02/09.
//
//  Copyright (c) 2009 Thinking Code Software Inc. http://www.thinkingcode.ca
//
//	Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
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

/**
 @mainpage Froth - Cocoa Web Application Framework
 <h3>Main API Classes</h3>
 - WebApplication
 - WebActionController
 - WebActiveController
 - WebLayoutView
 - WebActionView
 - WebRequest
 - WebResponse
 - WebSession
 - WebModelBase
 
 <h3>Background</h3>
 
 <p>Froth is a Objective-C web application framework that brings the power and simplicity of Cocoa development to the web. </p>
 <p>While froth web apps are technically deployable on many different platforms using <a href="http://www.cocotron.org" rel="nofollow">Cocotron</a>,
 currently our focus has been on the <a href="http://aws.amazon.com/ec2/" rel="nofollow">Amazon EC2</a> cloud. </p>
 
 <b>Benefits of Froth</b>
 - Uses the tools and language Mac and iPhone developers have come to know and love.
 - Reuse existing objc/c code from desktop applications. 
 - Simple view templating support.
 - Very fast and scalable.
 - Affordable hosting on Amazon EC2 Cloud.
 - Multiple builds and deployments using standard Xcode deployments.
 
 <p>
 <strong>Simple Example</strong>
 </p>
 
 \code
 @interface WAHelloController : WebActiveController {
 }
 
 // http://myexample.com/hello
 - (id)helloAction:(WebRequest*)req;
 
 // http://example.com/goodbye
 - (id)goodbyeAction:(WebRequest*)req;
 
 @end
 
 
 @implementation WAHelloController
 
 - (id)helloAction:(WebRequest*)req {
 return "Hello World";
 }
 
 - (id)goodbyeAction:(WebRequest*)req {
 return "Goodbye"
 }
 
 @end
 \endcode
 
 */

#define FROTH_VERSION_STRING @"0.5.0"

#import "HTTPd.h"
#import "WebFastCgiController.h"

#import "Froth+Defines.h"

#import "WebApplication.h"
#import "WebActionController.h"
#import "WebRequest.h"
#import "WebResponse.h"
#import "WebLayoutView.h"
#import "WebActionView.h"
#import "WebComponent.h"

#import "WebSession+User.h"

#import "WebDataSource.h"
#import "SDBDataSource.h"
#import "WebModelPredicate.h"

//Error system
#import "Froth+Exceptions.h"

//Base Action Controllers
#import "WebActiveController.h"

//Useful Additions
#import "NSDictionary+Query.h"
#import "NSData+Utilities.h"
#import "NSString+Utilities.h"
#import "NSString+Crypto.h"
#import "NSString+Regex.h"
#import "NSDateScealaTypes.h"
#import "WebRequest+Params.h"
#import "NSXMLElementAdditions.h"
#import "NSDate+Utilities.h"

//Utilities and Data Connectors
#import "SDBDataConnector.h"
#import "MemcachedConnector.h"
#import "MGTemplateMarker.h"
#import "AGRegexTemplateMatcher.h"
#import "DDXML.h"
#import "JSON.h"

//Templating Filters and Functions
#import "WKValueComparisonFilters.h"
#import "NSNumber+TemplateUtilities.h"
#import "NSArray+TemplateUtilities.h"

//Email
#import "WebMailer.h"