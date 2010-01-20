//
//  ApplicationController.h
//  Froth
//
//  Created by Allan Phillips on 23/02/09.
//
//  Copyright (c) 2010 Thinking Code Software Inc. http://www.thinkingcode.ca
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

#import "FrothTestingController.h"
#import "WebRequest+Params.h"
#import "FrothTestCase.h"

@implementation FrothTestingController

- (id)runtestAction:(WebRequest*)req {
	NSMutableString* outs = [[[NSMutableString alloc] init] autorelease];
	
	[outs appendString:@"<html><body>"];
	[outs appendString:@"<h1>Running Froth Test Case</h1>"];
	
	NSString* testName = [req firstParam];
	Class testClass = NSClassFromString(testName);
	if(testClass) {
		FrothTestCase* tcase = [[testClass alloc] init];
		[tcase setUp];
				
		for(NSString* testMethod in [tcase tests]) {
			NSLog(@"++start tests");
			SEL selector = NSSelectorFromString(testMethod);
			[tcase performSelector:selector];
		}
		
		[outs appendString:@"<div class='tests'>"];
		[outs appendFormat:@"<h3>[%@ %@]</h3>", testClass, testName];

		for(NSException* exp in [tcase results]) {
			NSString* testMethod = [[exp userInfo] objectForKey:@"methodName"];
			
			NSLog(@"FrothTestingController: +starting [%@ %@]", testName, testMethod);
			if([[exp name] hasPrefix:@"FRAssert"]) {	//Test exceptions
				
				BOOL pass = YES;
				if([[exp name] hasSuffix:@"Fail"]) {
					[outs appendString:@"<div class='test fail'>"];
					pass=NO;
				} else {
					[outs appendString:@"<div class='test pass'>"];
				}
				
				[outs appendFormat:@"<br><i><b>%@</b></i><br>%@<br>%@", [exp name], [exp reason], [exp userInfo]];
			
			} else {	//Not a built in exception by an application level exception, this to needs to be reported.
				[outs appendString:@"<div class='test fail'>"];
				[outs appendFormat:@"<h3>[%@ %@] - <i>Failed</i></h3>", testName, testMethod];
				[outs appendFormat:@"%@ %@", [exp name], [exp reason]];
			}
			
			[outs appendString:@"</div>"];
		}
		[outs appendString:@"</div>"];
		
		[tcase tearDown];
		[tcase release];
	} else {
		[outs appendFormat:@"No %@ test case class found", testName];
	}
	
	[outs appendString:@"</body></html>"];
	return outs;
}

@end
