//
//  SDBDataConnetor.h
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

#import "S3DataConnector.h"
#import "NSData+Utilities.h"
#import "NSString+Crypto.h"
#import "NSString+Utilities.h"
#import "DDXML.h"
#import "DDXMLElementAdditions.h"
#import "NSDate+Utilities.h"

#import "Froth+Exceptions.h"

#define S3CONNECTOR_HOST @"s3-us-west-1.amazonaws.com"

@implementation S3DataConnector

+ (S3DataConnector*)sharedDataConnectorForAccount:(NSString*)accountVal secret:(NSString*)secretVal {
	return [[[self alloc] initWithAccount:accountVal secret:secretVal] autorelease];
}

- (id)initWithAccount:(NSString*)accountVal secret:(NSString*)secretVal {
	if(self = [super init]) {
		secret = [secretVal retain];
		account = [accountVal retain];
	}
	return self;
}

- (void)dealloc {
	[secret release], secret = nil;
	[account release], account = nil;
	[super dealloc];
}

#pragma mark -
#pragma mark Private

//see http://docs.amazonwebservices.com/AmazonS3/2006-03-01/dev/index.html?ConstructingTheAuthenticationHeader.html

// HTTP Verb + '\n' +
// Content MD5 + '\n' +
// Content Type + '\n' +
// Date + '\n' +
// CanonicalizedAmzHeaders +
// CanonicalizedResourse;

- (NSString*)canonicalizedAmzHeadersFromRequest:(NSURLRequest*)req {
	NSArray* headers = [[req allHTTPHeaderFields] allKeys];
	headers = [headers sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	
	NSMutableString* outs = [[[NSMutableString alloc] init] autorelease];
	for(NSString* header in headers) {
		if([header hasPrefix:@"x-amz"]) {
			[outs appendFormat:@"%@:%@\n", [header lowercaseString], [[req allHTTPHeaderFields] valueForKey:header]];
		}
	}
	return outs;
}

- (NSString*)canonicalizedResourceFromRequest:(NSURLRequest*)req {	
	NSURL* requestURL = [req URL];
	NSString *requestQuery = [requestURL query];
    NSString *requestPath = [[requestURL path] urlEncoded];
    NSString *absoluteString = [requestURL absoluteString];
    if (requestQuery != nil) {
        NSString *withoutQuery = [absoluteString stringByReplacingOccurrencesOfString:requestQuery withString:@""];
        if (![requestPath hasSuffix:@"/"]&&[withoutQuery hasSuffix:@"/?"]) {
            requestPath = [NSString stringWithFormat:@"%@/", requestPath];            
        }
    } else if (![requestPath hasSuffix:@"/"]&&[absoluteString hasSuffix:@"/"]) {
        requestPath = [NSString stringWithFormat:@"%@/", requestPath];
    }
    
    /*if (!([operation isRequestOnService])&&([self virtuallyHosted])) {
        requestPath = [NSString stringWithFormat:@"/%@%@", [operation bucketName], requestPath];
    }*/
	
	if(!requestPath || requestPath.length < 1) {
		requestPath = @"/";
	}
		
	return requestPath;
}

- (void)signRequest:(NSMutableURLRequest*)req {
	NSMutableString* stringToSign = [NSMutableString string];
	[stringToSign appendFormat:@"%@\n", [[req HTTPMethod] uppercaseString]];
	
	if([req HTTPBody]) {
		[stringToSign appendFormat:@"%@\n", [[req HTTPBody] md5Digest]];
	} else {
		[stringToSign appendString:@"\n"];
	}
	
	if([req valueForHTTPHeaderField:@"content-type"]) {
		[stringToSign appendFormat:@"%@\n", [req valueForHTTPHeaderField:@"content-type"]];
	} else {
		[stringToSign appendString:@"\n"];
	}
	
	if(![req valueForHTTPHeaderField:@"Date"]) {
		NSString* dateStr = [[NSDate date] descriptionWithCalendarFormat:@"%a, %d %b %Y %H:%M:%S %z" timeZone:nil locale:nil];
		
#ifndef __APPLE__
		dateStr = [dateStr stringByReplacingOccurrencesOfString:@"0000" withString:@"GMT"];
#endif
		
		NSLog(@"dateStr:%@", dateStr);
		[req setValue:dateStr forHTTPHeaderField:@"Date"];
	}
	[stringToSign appendFormat:@"%@\n", [req valueForHTTPHeaderField:@"Date"]];
	
	//Add the cannonized amz headers
	[stringToSign appendString:[self canonicalizedAmzHeadersFromRequest:req]];
	
	//Add the cannonized resources
	[stringToSign appendString:[self canonicalizedResourceFromRequest:req]];
	
	NSLog(@"Should sign:%@", stringToSign);
	
	//Do the signing.
	NSString* signature = [stringToSign sha1HmacWithSecret:secret];
	
	//Add the signature
	[req setValue:[NSString stringWithFormat:@"AWS %@:%@", account, signature] forHTTPHeaderField:@"Authorization"];
}

#pragma mark -
#pragma mark Bucket Management

- (NSArray*)getBuckets {
	NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@", S3CONNECTOR_HOST]]];
	[self signRequest:req]; //Always sign last
	NSError* nerror;
	NSData* result = [NSURLConnection sendSynchronousRequest:req returningResponse:nil error:&nerror];
	if(result) {
		NSXMLDocument* xml = [[NSXMLDocument alloc] initWithData:result options:0 error:nil];
		NSXMLElement* root = [xml rootElement];
		if([[root name] isEqualToString:@"Error"]) {
			froth_exception(@"S3DataConnectorAmazonRestException", [[root elementForName:@"Message"] stringValue]);
		} else {
			NSXMLElement* xbucket = [root elementForName:@"Buckets"];
			NSArray* xbuckets = [xbucket elementsForName:@"Bucket"];
			NSMutableArray* results = [NSMutableArray array];
			for(NSXMLElement* xb in xbuckets) {
				NSString* name = [[xb elementForName:@"Name"] stringValue];
				[results addObject:[NSDictionary dictionaryWithObjectsAndKeys:[[xb elementForName:@"CreationDate"] stringValue], @"CreationDate", name, @"Name", nil]];
			}
			return results;
		}
	} else if(nerror) {
		froth_exception(@"S3DataConnectorAmazonResultException", [nerror localizedDescription]);
	}
	return nil;
}

@end
