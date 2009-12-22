//
//  NSMutableString+Utilities.m
//  Froth
//
//  Created by Allan Phillips on 21/07/09.
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

#import "NSMutableString+Utilities.h"


@implementation NSMutableString (Utilities)

- (void)trimWhitespace {
	/*
	 TODO: implement this in pure c for speed.
	 */
	
	//Remove fron chars
	unichar nChar;
	int i, c = [self length];
	for(i=0; i<c;i++) {
		nChar = [self characterAtIndex:i];
		if(0x09 == nChar || 0x0a == nChar || 0x0b == nChar || 0x0c == nChar || 0x0d == nChar || 0x20 == nChar) {
		} else {
			break;
		}
	}
	[self replaceCharactersInRange:NSMakeRange(0, i) withString:@""];
	
	//remove trail
	c = [self length];
	for(i=c-1; i>=0;i--) {
		nChar = [self characterAtIndex:i];
		if(0x09 == nChar || 0x0a == nChar || 0x0b == nChar || 0x0c == nChar || 0x0d == nChar || 0x20 == nChar) {
		} else {
			break;
		}
	}
	[self replaceCharactersInRange:NSMakeRange(i+1, [self length]-i-1) withString:@""];
}

@end
