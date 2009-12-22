//
//  WebModelPredicate.m
//  Froth
//
//  Created by Allan Phillips on 17/09/09.
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

#import "WebModelPredicate.h"
#import "Froth+Defines.h"
#import "Froth+Exceptions.h"

@implementation NSMutableDictionary (WebModelPredicate)

- (void)addKey:(NSString*)key like:(NSString*)value {
	[self setObject:froth_dic(@"like", @"condition", value, @"value") forKey:key];
}

- (void)addKey:(NSString*)key equal:(NSString*)value {
	[self setObject:value forKey:key];
}

- (void)addKey:(NSString*)key contains:(NSString*)value {
	[self setObject:froth_dic(@"contains", @"condition", value, @"value") forKey:key];
}

- (void)addKey:(NSString*)key endsWith:(NSString*)value {
	[self setObject:froth_dic(@"endsWith", @"condition", value, @"value") forKey:key];
}

- (void)addKey:(NSString*)key startsWith:(NSString*)value {
	[self setObject:froth_dic(@"startsWith", @"condition", value, @"value") forKey:key];
}

- (void)addKey:(NSString*)key betweenValue:(NSString*)start andValue:(NSString*)end {
	[self setObject:froth_dic(@"between", @"condition", start, @"value", end, @"value2") forKey:key];
}

- (void)addKey:(NSString*)key isIn:(NSArray*)array {
	froth_exception(@"FrothMethodNotImplemented", @"WebModelPredicate -addKey: isIn: is not implemented yet");
}

- (void)addIsNullKey:(NSString*)key {
	[self setObject:[NSNull null] forKey:key];
}

- (void)addOr:(NSDictionary*)orConditions {
	[self setObject:orConditions forKey:@"or"];
}

- (void)addAnd:(NSDictionary*)andBlock {
	[self setObject:andBlock forKey:@"and"];
}

@end
