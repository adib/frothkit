//
//  NSString+Utilities.m
//  Froth
//
//  Created by Allan Phillips on 08/07/09.
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

#import "NSString+Utilities.h"
#import "AGRegex.h"

#ifndef __APPLE__
#import <uuid/uuid.h>
#endif

@implementation NSString (Utilities)

+ (NSString*)guid {
#ifdef __APPLE__
	return [[NSProcessInfo processInfo] globallyUniqueString];
#else
	/* Requires libuuid on linux */
	uuid_t auuid;
	uuid_generate_time(auuid);
	
	char parsed[36];
	uuid_unparse(auuid, parsed);
	
	NSString* uuidString = [[NSString alloc] initWithBytes:parsed length:sizeof(parsed) encoding:NSUTF8StringEncoding];
	
	uuid_clear(auuid);
	
	return uuidString;
#endif
}

- (BOOL)containsString:(NSString *)aString {
    return [self containsString:aString ignoringCase:NO];
}

- (BOOL)containsString:(NSString *)aString ignoringCase:(BOOL)flag {
    unsigned mask = (flag ? NSCaseInsensitiveSearch : 0);
    NSRange range = [self rangeOfString:aString options:mask];
    return (range.length > 0);
}

- (NSString*)stripedSignature {
	NSString* nString = [self stringByReplacingOccurrencesOfString:@"/" withString:@""];
	nString = [nString stringByReplacingOccurrencesOfString:@"+" withString:@""];
	return [nString stringByReplacingOccurrencesOfString:@"=" withString:@""];
}

- (NSString*)underscoreToCamelCase {
	NSArray* parts = [self componentsSeparatedByString:@"_"];
	if(parts.count>1) {
		NSMutableString* contName = [NSMutableString string];
		NSString* first = [parts objectAtIndex:0];
		for(NSString* part in parts) {
			if(part == first)
				[contName appendString:part];
			else
				[contName appendString:[part capitalizedString]];
		}
		return contName;
	}
	return self;
}

- (NSString*)urlDecoded {
	return self;
}

- (NSString*)urlEncoded {
	return self;
}

/*
	See here for specs
	http://www.w3.org/MarkUp/html-spec/html-spec_8.html#SEC8.2.1
	http://www.w3schools.com/TAGS/ref_urlencode.asp
 */
- (NSString*)postFormDecoded {
	NSString* decoded = [self stringByReplacingOccurrencesOfString:@"+" withString:@" "];
	decoded = [decoded stringByReplacingOccurrencesOfString:@"%20" withString:@" "];
	decoded = [decoded stringByReplacingOccurrencesOfString:@"%0D%0A" withString:@"\n"];
	decoded = [decoded stringByReplacingOccurrencesOfString:@"%40" withString:@"@"];
	decoded = [decoded stringByReplacingOccurrencesOfString:@"%3A" withString:@":"];
	decoded = [decoded stringByReplacingOccurrencesOfString:@"%2C" withString:@","];
	decoded = [decoded stringByReplacingOccurrencesOfString:@"%2F" withString:@"/"];
	decoded = [decoded stringByReplacingOccurrencesOfString:@"%3C" withString:@"<"];
	decoded = [decoded stringByReplacingOccurrencesOfString:@"%3E" withString:@">"];
	decoded = [decoded stringByReplacingOccurrencesOfString:@"%23" withString:@"#"];
	decoded = [decoded stringByReplacingOccurrencesOfString:@"%25" withString:@"%"];
	decoded = [decoded stringByReplacingOccurrencesOfString:@"%22" withString:@"\""];
	decoded = [decoded stringByReplacingOccurrencesOfString:@"%3F" withString:@"?"];
	decoded = [decoded stringByReplacingOccurrencesOfString:@"%7B" withString:@"{"];
	decoded = [decoded stringByReplacingOccurrencesOfString:@"%7D" withString:@"}"];
	decoded = [decoded stringByReplacingOccurrencesOfString:@"%3D" withString:@"="];
	decoded = [decoded stringByReplacingOccurrencesOfString:@"%2B" withString:@"+"];
	decoded = [decoded stringByReplacingOccurrencesOfString:@"%3B" withString:@";"];
	return [decoded urlDecoded];
}

- (NSString*)postFormEncoded {
	NSString* encoded = [self stringByReplacingOccurrencesOfString:@" " withString:@"+"];
	encoded = [encoded stringByReplacingOccurrencesOfString:@"\n" withString:@"%0D%0A"];
	encoded = [encoded stringByReplacingOccurrencesOfString:@"@" withString:@"%40"];
	encoded = [encoded stringByReplacingOccurrencesOfString:@":" withString:@"%3A"];
	encoded = [encoded stringByReplacingOccurrencesOfString:@"," withString:@"%2C"];
	return [encoded urlEncoded];	
}

- (NSString*)html {
	NSString* html = [self stringByReplacingOccurrencesOfString:@"\n" withString:@"<br>"];
	return html;
}

- (NSString*)htmlSanatize {
	NSString* save = [self stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];
	save = [save stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
	save = [save stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
	save = [save stringByReplacingOccurrencesOfString:@"\"" withString:@"&quot;"];
	return save;
}

- (NSString*)ejson {
	static NSMutableCharacterSet *kEscapeChars;
    NSMutableString* json = [NSMutableString string];
	
	if( ! kEscapeChars ) {
        kEscapeChars = [[NSMutableCharacterSet characterSetWithRange: NSMakeRange(0,32)] retain];
        [kEscapeChars addCharactersInString: @"\"\\"];
    }
    
	//Already has this...
    //[json appendString:@"\""];
    
    NSRange esc = [self rangeOfCharacterFromSet:kEscapeChars];
    if ( !esc.length ) {
        // No special chars -- can just add the raw string:
        [json appendString:self];
        
    } else {
        NSUInteger length = [self length];
        for (NSUInteger i = 0; i < length; i++) {
            unichar uc = [self characterAtIndex:i];
            switch (uc) {
                case '"':   [json appendString:@"\\\""];       break;
                case '\\':  [json appendString:@"\\\\"];       break;
                case '\t':  [json appendString:@"\\t"];        break;
                case '\n':  [json appendString:@"\\n"];        break;
                case '\r':  [json appendString:@"\\r"];        break;
                case '\b':  [json appendString:@"\\b"];        break;
                case '\f':  [json appendString:@"\\f"];        break;
                default:    
                    if (uc < 0x20) {
                        [json appendFormat:@"\\u%04x", uc];
                    } else {
						//TODO: fix for better performance for cocotron/froth
						[json appendFormat:@"%c", uc];
                        //CFStringAppendCharacters((CFMutableStringRef)json, &uc, 1);
                    }
                    break;
                    
            }
        }
    }
    
    //[json appendString:@"\""];
    return json;
}

- (NSString*)firstLetterCaptialized {
	/*
		Currently our amazon deployment target has an issue where the first and last caracter us getting uppercased
	 */
#ifdef __APPLE__
	NSRange startRange = NSMakeRange(0, 1);
	return [self stringByReplacingCharactersInRange:startRange withString:[[self substringWithRange:startRange] uppercaseString]];
#else
	//An awfull hack to fix the bug.
	NSString* firstCharCapital = [[self substringWithRange:NSMakeRange(0, 1)] uppercaseString];
	NSString* lastPartOfString = [self substringWithRange:NSMakeRange(1, self.length-1)];
	return [firstCharCapital stringByAppendingString:lastPartOfString];
#endif
}

- (BOOL)isValidEmail {
	AGRegex * email = [AGRegex regexWithPattern:@"^(\\w|\\-|\\_|\\.)+@((\\w|\\-|\\_)+\\.)+[a-zA-Z]{2,}$"];
	if([email findInString:self])
		return YES;
	
	return NO;
}

@end
