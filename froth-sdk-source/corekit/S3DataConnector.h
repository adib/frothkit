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

#import <Foundation/Foundation.h>
#import "S3Bucket.h"

extern NSString * const S3AccessControlPrivate;			//@"private",
extern NSString * const S3AccessControlPublicRead;		//@"public-read",
extern NSString * const S3AccessControlPublicFull;		//@"public-read-write",
extern NSString * const S3AccessControlAuthRead;		//@"authenticated-read",
extern NSString * const S3AccessControlBucketOwnerRead;	//@"bucket-owner-read",
extern NSString * const S3AccessControlBucketOwnerFull;	//@"bucket-owner-full-control"

/*! 
 \brief	[INCOMPLETE] Provides an connector for accessing Amazon S3 data.
 */
@interface S3DataConnector : NSObject {
	NSString* secret;
	NSString* account;
}

/*!
 \brief Provides a shared data connector given account and aws secret
 */
+ (S3DataConnector*)sharedDataConnectorForAccount:(NSString*)account secret:(NSString*)secret;
- (id)initWithAccount:(NSString*)account secret:(NSString*)secret;

/*!
 \brief Returns an array of NSDictionary representation of buckets connector's zone
 
 The dictionary objects in the array contain the following key values corresponding to Amazon s3 xml response names
 - Name, NSString
 - CreationDate, NSDate
 */	
- (NSArray*)getBuckets;

/*!
 \brief Creates a bucket on the amazon ec2 for account
 
 \param name			The name of the bucket to create
 \return	False if the operation failed
 */
- (BOOL)createBucketWithName:(NSString*)name;

/*!
 \brief Deletes the bucket with given name.
 \param name		The name of the bucket to delete.
 \return FALSE if the operation failed
 */
- (BOOL)deleteBucketWithName:(NSString*)name;

/*!
 \brief	Gets the keys (files) from a bucket on the amazon ec2 for account
 
 \param name		The name of the bucket
 \param path		Allows for a file based retreival of objects. pass null to get all from bucket
 \param maxKeys	The maximum amount of keys (files) to retrieve from the bucket, pass < 0 to retreive all.
 \param from		The start index to reteive keys (usefull for pagenation) 0 to start from beginning.
 \return nil if the opperation failed, otherwise an autoreleased bucket
 */
- (S3Bucket*)getBucketWithName:(NSString*)name path:(NSString*)path from:(int)marker max:(int)maxKeys;

- (BOOL)saveObjectWithData:(NSData*)data 
					bucket:(NSString*)bucket 
					  name:(NSString*)objName 
			   contentType:(NSString*)contentType
				  encoding:(NSString*)encoding
				   expires:(NSTimeInterval)seconds
					access:(NSString*)acl
					  meta:(NSDictionary*)meta;

- (NSData*)getObjectWithName:(NSString*)name fromBucket:(NSString*)bucket;

@end

