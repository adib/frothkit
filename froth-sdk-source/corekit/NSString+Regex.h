//
//  NSString+Regex.h
//  Froth
//
//  Created by Allan Phillips on 19/07/09.
//  Copyright 2009 Thinking Code Software Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString (Regex)

- (NSRange)rangeOfRegex:(NSString*)regex inRange:(NSRange)range capture:(NSUInteger)res;

- (BOOL)matchesPattern:(NSString*)regex;

@end
