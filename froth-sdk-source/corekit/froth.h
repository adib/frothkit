 //
 //
 //  froth.h
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
 @mainpage Froth Web Application Enviorment for Cocoa Developers
 
 <h3>Background</h3>
 TODO...
 
 <h3>Templating</h3>
 Froth supports a simple yet expandable templating language built on top of Matt Gammels excelent templating code MGTemplate. <br>
 <i>See WebLayoutView and WebActionView for templating details</i>
 
 <h3>Resource Mapping</h3>
 Froth Supports a powerful resource mapping system for mapping web app actions to a specific template based on the extention. This can be used to 
 render xml, json, binary versions of a item without changing the controller layer.
 
*/
 
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
#import "NSString+Regex.h"
#import "NSDateScealaTypes.h"
#import "WebRequest+Params.h"
#import "NSXMLElementAdditions.h"

//Utilities and Data Connectors
#import "SDBDataConnector.h"
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