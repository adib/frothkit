//
//  NSDateTests.m
//  FrothKit
//
//  Created by Allan Phillips on 12/01/10.
//  Copyright 2010 Thinking Code Software Inc. All rights reserved.
//

#import "NSDateTests.h"
#import "NSDate+Utilities.h"

#import <Foundation/NSPlatform.h>

@implementation NSDateTests

- (NSArray*)tests {
	return [NSArray arrayWithObject:@"test_dateWithString_Format_"];
}

- (void)dateWithStringTest:(NSString*)testDate currectTimeInterval:(NSTimeInterval)testInterval {
	NSDate* date = [NSDate dateWithString:testDate format:@"%Y-%m-%d %H:%M:%S %z"];
	
	if(date) {
		
		NSTimeInterval convertedInterval = [date timeIntervalSince1970];
		if(convertedInterval != testInterval) {
			FRFail(@"Date [%@] is not converted properly [CURRECT:%f]!=[FAILED:%f]", testDate, testInterval, convertedInterval);
		}
		
		FRPass(@"Date converted with string [%@] is [%@][%f])<br>Date from Interval [%f] is [%@].", 
			   testDate, [date description], [date timeIntervalSince1970], 
			   testInterval, [[NSDate dateWithTimeIntervalSince1970:testInterval] description]);
		
		//Test changing the time zone to UTC
		[(NSCalendarDate*)date setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
		
		FRPass(@"NSCalendarDate -setTimeZone Initial [%@] to UTC is [%@]", testDate, [date description]);
		
	} else {
		FRFail(@"Nil date was returned for test");
	}
}

- (void)test_dateWithString_Format_ {	

	FRPass(@"current time:%@", [[NSDate date] description]);
	[self dateWithStringTest:@"2018-05-02 19:57:00 -0700" currectTimeInterval:1525316220.00];
	[self dateWithStringTest:@"2018-05-02 19:57:00 -0600" currectTimeInterval:1525312620.00];
	[self dateWithStringTest:@"2018-05-02 19:57:00 -0400" currectTimeInterval:1525305420.00];
	[self dateWithStringTest:@"2018-05-02 19:57:00 +0400" currectTimeInterval:1525276620.00];
	[self dateWithStringTest:@"2018-05-02 19:57:00 +0600" currectTimeInterval:1525269420.00];
	[self dateWithStringTest:@"2018-05-02 19:57:00 +0700" currectTimeInterval:1525265820.00];
	
	[self dateWithStringTest:@"2001-10-02 2:57:00 -0700" currectTimeInterval:1002016620.00];
	
}

@end
