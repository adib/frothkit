//
//  NSDate+Utilities.m
//  Froth
//
//  Created by Allan Phillips on 08/07/09.
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

#import "NSDate+Utilities.h"


@implementation NSDate (Utilities)


+ (NSDate*)dateWithString:(NSString*)str format:(NSString*)formating {
	NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] initWithDateFormat:nil allowNaturalLanguage:NO];
	[dateFormatter setDateFormat:formating];
	NSDate* date = [dateFormatter dateFromString:str];	
	
	[dateFormatter release];
	return date;
}

+ (NSDate*)isoDateFromString:(NSString*)str {
	static NSDateFormatter* kISODateFormatter; 
	if(!kISODateFormatter) 
		kISODateFormatter = [[NSDateFormatter alloc] initWithDateFormat:@"%Y-%m-%dT%H:%M:%S.%F%Z" allowNaturalLanguage:NO];
	return [kISODateFormatter dateFromString:str];
}

@end
