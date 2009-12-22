//
//  NSString+Regex.m
//  Froth
//
//  Created by Allan Phillips on 19/07/09.
//  Copyright 2009 Thinking Code Software Inc. All rights reserved.
//

#import "NSString+Regex.h"
#import "AGRegex.h"
#import "Froth+Exceptions.h"

@implementation NSString (Regex)

- (NSRange)rangeOfRegex:(NSString*)regex inRange:(NSRange)range capture:(NSUInteger)res {
	AGRegex* reg = [AGRegex regexWithPattern:regex];
	if(!reg) {
		froth_exception(@"NSStringRegexException", @"No regex instance for regex string:%@", regex);
	}
	
	AGRegexMatch* match = [reg findInString:self range:range];
	if(!match) 
		return (NSRange){NSNotFound,0};
	
	return [match rangeAtIndex:res];
}

- (BOOL)matchesPattern:(NSString*)regex {
	AGRegex* reg = [AGRegex regexWithPattern:regex];
	if(!reg)
		froth_exception(@"NSStringRegexException", @"Regex syntex is wrong for NSString+Regex -matchesPattern:");
		
	AGRegexMatch* match = [reg findInString:self];
	if(match && [[match string] isEqualToString:self])
		return YES;
	return NO;
}

@end
