//
//  ApplicationController.h
//  Froth
//
//  Created by Allan Phillips on 23/02/09.
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

#import "S3DataConnectorTests.h"
#import "Froth+Defines.h"
#import "Froth+Exceptions.h"

@implementation S3DataConnectorTests

- (NSArray*)tests {
	return [NSArray arrayWithObjects:/*@"test_getBuckets", 
			@"test_getBucketWithName_", 
			@"test_createBucketWithName_",*
			/*@"test_deleteBucketWithName_",*/
			@"test_saveObjectWithData_", nil];
}

- (void)setUp {
	connector = [[S3DataConnector sharedDataConnectorForAccount:[[[NSBundle mainBundle] infoDictionary] valueForKey:@"AmazonKey"]
														secret:[[[NSBundle mainBundle] infoDictionary] valueForKey:@"AmazonSecret"]] retain];
}

- (void)tearDown {
	[connector release];
}

- (void)test_getBuckets {
	NSArray* buckets = [connector getBuckets];
		
	if(buckets.count>0) {
		FRPass([NSString stringWithFormat:@"%@", buckets]);
	} else {
		FRFail(@"Array size is 0 for get buckets test");
	}
}

- (void)test_getBucketWithName_ {
	S3Bucket* bucket = [connector getBucketWithName:@"froth-ami-r1" path:@"froth-ami-r1.manifest" from:0 max:-1]; //path could be nil.
	NSLog(@"bucketcount%i", bucket.keys.count);
	if(bucket.keys.count>0) {
		FRPass(@"Backet Data:%@", [bucket keys]);
	} else {
		FRFail(@"Bucket [%@] should not be empty...", [bucket name]);
	}
}

- (void)test_createBucketWithName_ {
	if([connector createBucketWithName:@"froth-test-bucket"]) {
		FRPass(@"Bucket 'froth-test-bucket' was successfully created");
	} else {
		FRFail(@"Bucket 'froth-test-bucket' failed to create");
	}
}

- (void)test_deleteBucketWithName_ {
	if([connector deleteBucketWithName:@"froth-test-bucket"]) {
		FRPass(@"Bucket 'froth-test-bucket' was successfully deleted");
	} else {
		FRFail(@"Bucket 'froth-test-bucket' failed to delete");
	}
}

- (void)test_saveObjectWithData_ {
	if([connector saveObjectWithData:[@"This is a test with sime interesting content asdf asdf awef awef adefawefa wefw" dataUsingEncoding:NSUTF8StringEncoding]  
							  bucket:@"froth-test-bucket"
								name:[NSString stringWithFormat:@"testdoc-%f.txt", [[NSDate date] timeIntervalSinceReferenceDate]] 
						 contentType:@"text/plain" 
							encoding:nil 
							 expires:-1 
							  access:nil 
								meta:nil]) 
	{
		FRPass(@"Test object -textdoc.txt saved to bucket");
	} else {
		FRFail(@"Teast object -textdoc.txt failed to save to bucket");
	}
}

@end
