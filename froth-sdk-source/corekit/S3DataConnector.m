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

#import <Foundation/NSHTTPURLResponse.h>

//Should be same location as ec2 instance to avoid redirection speed.
#define S3CONNECTOR_HOST @"s3.amazonaws.com"

NSString * const S3AccessControlPrivate =@"private";
NSString * const S3AccessControlPublicRead =@"public-read";
NSString * const S3AccessControlPublicFull =@"public-read-write";
NSString * const S3AccessControlAuthRead =@"authenticated-read";
NSString * const S3AccessControlBucketOwnerRead =@"bucket-owner-read";
NSString * const S3AccessControlBucketOwnerFull =@"bucket-owner-full-control";

@interface S3Bucket (S3DataConnectorInternal)
- (id)initWithConnector:(S3DataConnector*)connector name:(NSString*)nameVal subPath:(NSString*)pathVal marker:(int)mark max:(int)mx;
- (void)setHasMore:(BOOL)more;
@end

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
	
	if(!requestPath || requestPath.length < 1) {
		requestPath = @"/";
	}
	
	NSString* urlStr = [[req URL] host];
	NSArray* doms = [urlStr componentsSeparatedByString:@"."];
	NSArray* refDoms = [S3CONNECTOR_HOST componentsSeparatedByString:@"."];
	if (![[doms objectAtIndex:0] isEqualToString:[refDoms objectAtIndex:0]]) {
		requestPath = [NSString stringWithFormat:@"/%@%@", [doms objectAtIndex:0], requestPath];
	}
		
	return requestPath;
}

- (void)signRequest:(NSMutableURLRequest*)req {
	NSMutableString* stringToSign = [NSMutableString string];
	[stringToSign appendFormat:@"%@\n", [[req HTTPMethod] uppercaseString]];
	
	if([req HTTPBody]) {
		[stringToSign appendFormat:@"%@\n", [[req HTTPBody] md5DigestString]];
	} else if([req valueForHTTPHeaderField:@"content-md5"]) { //hmmm
		[stringToSign appendFormat:@"%@\n", [req valueForHTTPHeaderField:@"content-md5"]];
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
		NSXMLDocument* xml = [[[NSXMLDocument alloc] initWithData:result options:0 error:nil] autorelease];
		NSXMLElement* root = [xml rootElement];
		if([[root name] isEqualToString:@"Error"]) {
			froth_exception(@"S3DataConnectorAmazonRestException", [[root elementForName:@"Message"] stringValue]);
		} else {
			NSXMLElement* xbucket = [root elementForName:@"Buckets"];
			NSArray* xbuckets = [xbucket elementsForName:@"Bucket"];
			NSMutableArray* results = [NSMutableArray array];
			for(NSXMLElement* xb in xbuckets) {
				NSString* name = [[xb elementForName:@"Name"] stringValue];
				NSString* dateStr =[[xb elementForName:@"CreationDate"] stringValue];

				NSDate* date = [NSDate isoDateFromString:dateStr];
				[results addObject:[NSDictionary dictionaryWithObjectsAndKeys:date, @"CreationDate", name, @"Name", nil]];
			}
			return results;
		}
	} else if(nerror) {
		froth_exception(@"S3DataConnectorAmazonResultException", [nerror localizedDescription]);
	}
	return nil;
}

- (BOOL)m_fetchNext:(S3Bucket*)bucket {
	return FALSE; //TODO: Implement me!
}

- (S3Bucket*)getBucketWithName:(NSString*)name path:(NSString*)path from:(int)marker max:(int)maxKeys {
	NSMutableString* requestStr = [[[NSMutableString alloc] init] autorelease];
	[requestStr appendFormat:@"http://%@.%@", name, S3CONNECTOR_HOST];
	if(path)
		[requestStr appendFormat:@"?prefix=%@", path];
	if(marker>0)
		[requestStr appendFormat:@"&marker=%i", marker];
	if(maxKeys>0) {
		[requestStr appendFormat:@"&max-keys=%i", maxKeys];
	}
	
	NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestStr]];
	[self signRequest:req];
	
	NSError* nerror;
	NSData* result = [NSURLConnection sendSynchronousRequest:req returningResponse:nil error:&nerror];
	if(result) {
		NSXMLDocument* xml = [[[NSXMLDocument alloc] initWithData:result options:0 error:nil] autorelease];
		NSXMLElement* root = [xml rootElement];
		if([[root name] isEqualToString:@"Error"]) {
			froth_exception(@"S3DataConnectorAmazonRestException", [[root elementForName:@"Message"] stringValue]);
		} else {
			S3Bucket* bucket = [[S3Bucket alloc] initWithConnector:self name:name subPath:path marker:marker max:maxKeys];
			[bucket setHasMore:[[[root elementForName:@"IsTruncated"] stringValue] boolValue]];
			
			//Uggh!
			NSMutableArray* keys = (NSMutableArray*)[bucket keys];
			
			NSArray* contents = [root elementsForName:@"Contents"];
			for(NSXMLElement* element in contents) {
				//Could move this to a shared method for objects
				NSString* key = [[element elementForName:@"Key"] stringValue];
				NSDate* lastModified = [NSDate isoDateFromString:[[element elementForName:@"LastModified"] stringValue]];
				NSString* etag = [[[element elementForName:@"ETag"] stringValue] stringByReplacingOccurrencesOfString:@"\"" withString:@""];
				NSNumber* size = [NSNumber numberWithInt:[[[element elementForName:@"Size"] stringValue] intValue]];
				
				//TODO: add owner information http://docs.amazonwebservices.com/AmazonS3/latest/API/
				[keys addObject:[NSDictionary dictionaryWithObjectsAndKeys:key, @"Key", lastModified, @"LastModified", etag, @"ETag", size, @"Size", nil]];
			}
			
			return [bucket autorelease];
		}
	}
	return nil;
}

- (BOOL)createBucketWithName:(NSString*)name {
	NSMutableString* requestStr = [[[NSMutableString alloc] init] autorelease];
	[requestStr appendFormat:@"http://%@.%@", name, S3CONNECTOR_HOST];
	
	NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestStr]];
	[req setHTTPMethod:@"PUT"];
	[self signRequest:req];
	
	NSError* nerror;
	NSHTTPURLResponse* response = nil;
	[NSURLConnection sendSynchronousRequest:req returningResponse:&response error:&nerror];
	
	if(response && [response statusCode] == 404) {
		return TRUE;
	} 
	return TRUE; //See NSURLConnection_FoundationCompletions.m:145
}

- (BOOL)deleteBucketWithName:(NSString*)name {
	NSMutableString* requestStr = [[[NSMutableString alloc] init] autorelease];
	[requestStr appendFormat:@"http://%@.%@", name, S3CONNECTOR_HOST];
	
	NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestStr]];
	[req setHTTPMethod:@"DELETE"];
	[self signRequest:req];
	
	NSError* nerror;
	NSHTTPURLResponse* response = nil;
	[NSURLConnection sendSynchronousRequest:req returningResponse:&response error:&nerror];
	
	if(response && [response statusCode] == 404) {
		return TRUE;
	} 
	return TRUE; //See NSURLConnection_FoundationCompletions.m:145
}

- (BOOL)saveObjectWithData:(NSData*)data 
					bucket:(NSString*)bucket 
					  name:(NSString*)objName 
			   contentType:(NSString*)contentType
				  encoding:(NSString*)encoding
				   expires:(NSTimeInterval)seconds
					access:(NSString*)acl
					  meta:(NSDictionary*)meta
{
	if(data && data.length > 0) {
		NSMutableString* requestStr = [[[NSMutableString alloc] init] autorelease];
		[requestStr appendFormat:@"http://%@.%@/%@", bucket, S3CONNECTOR_HOST, objName];
		
		NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestStr]];
		[req setHTTPMethod:@"PUT"];
		
		//Generate the md5 for security for prevention of man-in-the-middle
		//[req setValue:[data md5DigestString] forHTTPHeaderField:@"Content-MD5"];
		
		//Gets set automatically by libCurl..
		//[req setValue:[NSString stringWithFormat:@"%i", data.length] forHTTPHeaderField:@"Content-Length"];
		
		if(contentType)
			[req setValue:contentType forHTTPHeaderField:@"Content-Type"];
		if(encoding) 
			[req setValue:encoding forHTTPHeaderField:@"Content-Encoding"];
		if(seconds>0)
			[req setValue:[NSString stringWithFormat:@"%f", seconds*1000.0] forHTTPHeaderField:@"expires"];
		if(acl)
			[req setValue:acl forHTTPHeaderField:@"x-amz-acl"];
		
		if(meta) {
			NSArray* allKeys = [meta allKeys];
			for(NSString* key in allKeys) {
				[req setValue:[meta valueForKey:key] forHTTPHeaderField:[NSString stringWithFormat:@"x-amz-meta-%@", key]];
			}
		}
		
		[self signRequest:req];
		[req setHTTPBody:data];
		
		NSError* nerror;
		NSHTTPURLResponse* response = nil;
		NSData* result = [NSURLConnection sendSynchronousRequest:req returningResponse:&response error:&nerror];
		
		if(response && [response statusCode] == 200) {
			return TRUE;
		} else if(result) {
			NSLog(@"response:%@", [[[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding] autorelease]);
			return FALSE;
		}
		return TRUE;
	} 
	return FALSE;
}

@end
