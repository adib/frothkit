//
//  NSDate+SBJSON.m
//  Froth
//
//  Created by Allan Phillips on 13/09/09.
//  Copyright 2009 Thinking Code Software Inc. All rights reserved.
//

#import "NSDate+SBJSON.h"


@implementation NSDate (SBJSON)

- (id)proxyForJson {
#ifdef __APPLE__
	return [self description];
#else
	//Temp hack to get dates working better.
	NSString* dateStr = [self description];
	NSMutableArray* dateComps = [NSMutableArray arrayWithArray:[dateStr componentsSeparatedByString:@" "]];
	NSString* tzComp = [dateComps lastObject];
	if(![tzComp hasPrefix:@"-"]) {
		[dateComps removeLastObject];
		[dateComps addObject:[NSString stringWithFormat:@"+%@", tzComp]];
		return [dateComps componentsJoinedByString:@" "];
	} else {
		return dateStr;
	}
#endif
}

@end
