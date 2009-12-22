//
//  WKStringCompairFilter.m
//  Froth
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
#import "WKValueComparisonFilters.h"


@implementation WKValueComparisonFilters

- (NSArray *)filters {
	return [NSArray arrayWithObjects:@"string_is_equal", @"string_has_prefix", @"string_has_suffix", @"string_contains", nil];
}

#pragma mark -
- (NSObject*)_string_is_equalFunctionWithArgs:(NSArray*)args onValue:(NSObject*)value {
//	NSLog(@"value:%@ args:%@", value, [args objectAtIndex:0]);
	return [NSNumber numberWithBool:[[args objectAtIndex:0] isEqualToString:(NSString*)value]];
}

#pragma mark -
- (NSObject *)filterInvoked:(NSString *)filter withArguments:(NSArray *)args onValue:(NSObject *)value {
	SEL functionSel = NSSelectorFromString([NSString stringWithFormat:@"_%@FunctionWithArgs:onValue:", filter]);
	return [self performSelector:functionSel withObject:args withObject:value];
}

@end
