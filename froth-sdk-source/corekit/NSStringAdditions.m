#import "NSStringAdditions.h"

@implementation NSString (NSStringAdditions)

- (const xmlChar *)xmlChar
{
	return (const xmlChar *)[self UTF8String];
}

- (NSString *)stringByTrimmingWhitespace
{
	NSMutableString *mStr = [self mutableCopy];
	[mStr trimWhitespace];
	
	NSString *result = [mStr copy];
	
	[mStr release];
	return [result autorelease];
}

@end
