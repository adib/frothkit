//
//  S3Bucket.h
//  FrothKit
//
//  Created by Allan Phillips on 14/01/10.
//  Copyright 2010 Thinking Code Software Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class S3DataConnector;

/*! 
	\brief Immutable Information about a retreived bucket.
*/
@interface S3Bucket : NSObject {	
	NSString* name;
	NSString* subPath;
	NSMutableArray* keys;
	BOOL hasMore;

@private 
	S3DataConnector* m_connector;

	int m_marker;
	int m_increment;
}

/*
	\brief The name of the bucket.
*/
- (NSString*)name;

/*
	\brief The path for the bucket if used with S3DataConnector -getBucketWithName:path:maxKeys:from:
*/
- (NSString*)subPath;

/*!
	\brief The keys in order from the bucket.
	
	This is accumulated if secondary gets are processed useing markers and pagenation.
*/
- (NSArray*)keys;

/*!
	\brief If the bucket contains more keys not yet fetched.
 */
- (BOOL)hasMore;

/*!
	\brief Retreives additional keys if increment size is < total keys in bucket.
	\return FALSE if an error occured
 */
- (BOOL)fetchNext;

@end
