//
//  NSDictionary+Query.m
//  Froth
//
//  Created by Allan Phillips on 24/02/09.
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

#import "NSDictionary+Query.h"
#import "NSString+Utilities.h"

@implementation NSDictionary (Query)

+ (NSDictionary*)dictionaryWithQuery:(NSString*)urlQuery {
	if(!urlQuery || [urlQuery isEqualToString:@""]) return [NSDictionary dictionary];
	
	NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
	NSArray* kvs = [urlQuery componentsSeparatedByString:@"&"];
	for(NSString*cmp in kvs) {
		NSArray* kvcomps = [cmp componentsSeparatedByString:@"="];
		if(kvcomps.count > 1) {
			[dictionary setObject:[[kvcomps objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] forKey:[kvcomps objectAtIndex:0]];
		} else {
			[dictionary setObject:@"{{nil}}" forKey:cmp];
		}
	}
	return dictionary;
}

+ (NSDictionary*)dictionaryWithPostForm:(NSString*)postForm {
	NSArray *kv = [postForm componentsSeparatedByString:@"&"];
	NSMutableDictionary *p = [NSMutableDictionary dictionaryWithCapacity:[kv count]];
	for(NSString *i in kv) {
		NSArray *s = [i componentsSeparatedByString:@"="];
		if([s count] != 2)
			return nil;
		NSString* value = [[s objectAtIndex:1] stringByReplacingOccurrencesOfString:@"+" withString:@" "];
		value = [value postFormDecoded];
		[p setObject:[value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
			  forKey:[s objectAtIndex:0]];
	}
	return p;
}

- (NSString*)queryString {
	NSArray* allKeys = [self allKeys];
	if(!allKeys || allKeys.count < 1) return nil;
	
	NSMutableArray* comps = [NSMutableArray array];
	for(NSString* akey in allKeys) {
		NSString* value = [self objectForKey:akey];
		if([value isEqualToString:@"{{nil}}"]) {
			[comps addObject:akey];
		} else {
			[comps addObject:[NSString stringWithFormat:@"%@=%@", akey, [value stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
		}
	}
	return [comps componentsJoinedByString:@"&"];
}

@end
