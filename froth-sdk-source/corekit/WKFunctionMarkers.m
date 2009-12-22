//
//  WKFunctionMarkers.m
//  Froth
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

#import "WKFunctionMarkers.h"
#import "MGTemplateEngine.h"
#import "AGRegexTemplateMatcher.h"

//Load internal filters
#import "WKValueComparisonFilters.h"

#define VAR @"var"

@implementation WKFunctionMarkers

- (id)initWithTemplateEngine:(MGTemplateEngine *)engine {
	if(self = [super init]) {
		m_engine = engine;
	}
	return self;
}

- (NSArray *)markers {
	return [NSArray arrayWithObjects: VAR, nil];
}

- (NSArray *)endMarkersForMarker:(NSString *)marker {
	return nil;
}

- (NSObject *)markerEncountered:(NSString *)marker withArguments:(NSArray *)args inRange:(NSRange)markerRange 
				   blockStarted:(BOOL *)blockStarted blockEnded:(BOOL *)blockEnded 
				  outputEnabled:(BOOL *)outputEnabled nextRange:(NSRange *)nextRange 
			   currentBlockInfo:(NSDictionary *)blockInfo newVariables:(NSDictionary **)newVariables
{
	//Always returns an empty string, as no content should be inserted, only changes to "template" are made
	
	if ([marker isEqualToString:VAR]) {
		if (args && [args count] > 3 && *outputEnabled) {
			// Set variable arg1 to value seperatly parsed filter.
			
			//TODO: Make this much faster, possibly with "MGTemplateFunctions" protocal
			
			//NSLog(@"args %@", args);
			NSArray* params = [args subarrayWithRange:NSMakeRange(4, [args count]-4)];
			NSMutableArray* parsedParams = [NSMutableArray array];
			for(NSString* prop in params) {
				if([prop hasPrefix:@"fvar."]) {
					[parsedParams addObject:[prop stringByReplacingOccurrencesOfString:@"fvar." withString:@""]];
				} else {
					[parsedParams addObject:[NSString stringWithFormat:@"\"%@\"", prop]];
				}
			}
		
			NSString* filterString = [NSString stringWithFormat:@"{{ %@ | %@ %@ }}", 
									  [args objectAtIndex:3], [args objectAtIndex:2], 
									  [parsedParams componentsJoinedByString:@" "]];
			//NSLog(@"filterString:%@", filterString);
			
			MGTemplateEngine* templateEngine = [MGTemplateEngine templateEngine];
			[templateEngine setMatcher:[AGRegexTemplateMatcher matcherWithTemplateEngine:templateEngine]];
			[templateEngine loadFilter:[[WKValueComparisonFilters alloc] init]];
			
			//NSLog(@"existing vars:%@", [m_engine templateVariables]);
			
			NSString* results = [templateEngine processTemplate:filterString withVariables:[m_engine templateVariables]];
			//NSLog(@"results-->%@", results);
			
			NSDictionary *newVar = [NSDictionary dictionaryWithObject:results
															   forKey:[args objectAtIndex:0]];
			if (newVar) {
				*newVariables = newVar;
			}
		}
	}
	
	return nil;
}

- (void)engineFinishedProcessingTemplate {
}

@end
