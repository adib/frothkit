//
//  WebModelPredicate.h
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

#import <Foundation/Foundation.h>

/* 
	\brief Privides a query predicate for passing to WebModelBase's findAll/FirstWithConditions:
	
	Predicates can be nested to create complex operations.
 
	<pre>
	NSMutableDictionary* predicate = [WebModelPredicate predicate];
	[predicate addKey:@"people" like:@"john"];
	[predicate addIsNullKey:@"confirmed"];
	return [object findAllWithConditions:predicate]
	
*/
@interface NSMutableDictionary (WebModelPredicate)

- (void)addKey:(NSString*)key like:(NSString*)value;
- (void)addKey:(NSString*)key equal:(NSString*)value;
- (void)addKey:(NSString*)key contains:(NSString*)value;
- (void)addKey:(NSString*)key endsWith:(NSString*)value;
- (void)addKey:(NSString*)key startsWith:(NSString*)value;
- (void)addKey:(NSString*)key betweenValue:(NSString*)start andValue:(NSString*)end;
- (void)addKey:(NSString*)key isIn:(NSArray*)array;
- (void)addIsNullKey:(NSString*)key;
- (void)addOr:(NSDictionary*)orConditions;
- (void)addAnd:(NSDictionary*)andBlock;

@end
