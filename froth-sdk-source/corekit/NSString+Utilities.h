//
//  NSString+Utilities.h
//  Froth
//
//  Created by Allan Phillips on 08/07/09.
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
#import <Foundation/Foundation.h>

/* \brief URL and Web Encoding and Deconding specific for froth */
@interface NSString (Utilities)

+ (NSString*)guid;

//Converts a notified token, with the following open schema.
- (NSString*)stripedSignature;

- (NSString*)urlDecoded;
- (NSString*)urlEncoded;

// Provides application/x-www-form-urlencoded encoding and decoding.
- (NSString*)postFormDecoded;
- (NSString*)postFormEncoded;

// Converts all line breaks, tabs into %nbsps and <br> elements for nice html display.
- (NSString*)html;

// Escapes a string for json data. Templates can use this for display, ie {"key":"{{object.key.ejson}}"}
- (NSString*)ejson;

// Converts a string like this_string_here to thisStringHere
- (NSString*)underscoreToCamelCase;

- (NSString*)firstLetterCaptialized;

@end
