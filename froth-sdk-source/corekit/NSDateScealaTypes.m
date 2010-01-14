//
//  NSDateScealaTypes.m
//  Sceala
//
//  Created by Allan Phillips on 02/11/08.
//  Copyright 2008 Thinking Code Software Inc.. All rights reserved.
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

#import "NSDateScealaTypes.h"


@implementation NSDate (NSDateScealaTypes)

//Allows for yyyy-mm-dd-T-hh:mm:ss.xxxZ for subsecond precision
NSDate* dateFromISO8601WithSubSecond(NSString* str) {
	static NSDateFormatter* sISO8601_sub = nil;
	if (!sISO8601_sub) {
#ifdef __APPLE__
		sISO8601_sub = [[NSDateFormatter alloc] init];
		[sISO8601_sub setTimeStyle:NSDateFormatterFullStyle];
		[sISO8601_sub setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZZZ"];    // NOTE:  problem!
#else
		sISO8601_sub = [[NSDateFormatter alloc] initWithDateFormat:@"%Y-%m-%dT%H:%M:%S.%Fz%z" allowNaturalLanguage:YES];
#endif
	}
	if ([str hasSuffix:@"Z"]) { ///GMT
#ifdef __APPLE__
		str = [[str substringToIndex:(str.length-1)]  
			   stringByAppendingString:@"GMT"];
#else
		str = [[str substringToIndex:(str.length-1)]  
			   stringByAppendingString:@"z0000"];
#endif
	}
	return [sISO8601_sub dateFromString:str];
}

NSDate* dateFromISO8601(NSString* str) {
	static NSDateFormatter* sISO8601 = nil;
	if (!sISO8601) {
		sISO8601 = [[NSDateFormatter alloc] init];
#ifdef __APPLE__
		[sISO8601 setTimeStyle:NSDateFormatterFullStyle];

		[sISO8601 setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZ"];    // NOTE:  problem!
#else
		[sISO8601 setDateFormat:@"%Y-%m-%dT%H:%M:%Sz%z"];	//TODO: fix for firefox including subsecond presicion as .xx
#endif
	}
	if ([str hasSuffix:@"Z"]) {
#ifdef __APPLE__
		str = [[str substringToIndex:(str.length-1)]  
			   stringByAppendingString:@"GMT"];
#else
		str = [[str substringToIndex:(str.length-1)]  
			   stringByAppendingString:@"z0000"];
#endif
	}
	NSDate* date = [sISO8601 dateFromString:str];
	if(!date) 
		return dateFromISO8601WithSubSecond(str);
	
	NSLog(@"Generated date:%@", date);
	return date;
}

+ (NSDate*)dateFromScealaDateString:(NSString*)str {
	if(!str || [str isEqualToString:@""]) return nil;
	return  [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)([str doubleValue] / 1000)];
}

- (NSString*)scealaDateString {
	NSTimeInterval tiv = [self timeIntervalSince1970];
	double ms = (double)tiv * 1000;
	NSString* dateStr = [NSString stringWithFormat:@"%.0f", ms];
	NSLog(@"sceala date string:%@", dateStr);
	return dateStr;
}
@end

@implementation NSNull (Formatting)

- (NSString*)description {
	return @"((null))";
}

- (NSString*)scealaDateString {
	return [self description];
}

@end



