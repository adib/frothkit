//
//  SDBDataConnetor.h
//  Froth
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

#import <Foundation/Foundation.h>
#import "FrothTestCase+Macros.h"

/*!
	\brief [INCOMPLETE] A simple test case absract super class for running tests with FrothTestingController
 */
@interface FrothTestCase : NSObject {
	NSMutableArray* results;
}

- (NSArray*)results;

/*
	\brief Use one of the macros instead.
 */
- (void)addResult:(NSException*)result;

/*!
	\brief Setup the test case
 */
- (void)setUp;

/*!
	\brief Tear down the test case, do any cleanup
 */
- (void)tearDown;

//Temparary until we implement class introspection to automatically find all methods that begin with test_*
- (NSArray*)tests;

@end
