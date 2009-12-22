#import <Foundation/Foundation.h>
#import <libxml/tree.h>
#import "NSMutableString+Utilities.h"


@interface NSString (NSStringAdditions)

/**
 * xmlChar - A basic replacement for char, a byte in a UTF-8 encoded string.
**/
- (const xmlChar *)xmlChar;

- (NSString *)stringByTrimmingWhitespace;

@end
