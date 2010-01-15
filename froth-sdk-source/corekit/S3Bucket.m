//
//  S3Bucket.m
//  FrothKit
//
//  Created by Allan Phillips on 14/01/10.
//  Copyright 2010 Thinking Code Software Inc. All rights reserved.
//

#import "S3Bucket.h"
#import "S3DataConnector.h"

@interface S3DataConnector (S3BucketPrivate)
- (BOOL)m_fetchNext:(S3Bucket*)bucket;
@end

@implementation S3Bucket

- (id)initWithConnector:(S3DataConnector*)connector name:(NSString*)nameVal subPath:(NSString*)pathVal marker:(int)mark max:(int)mx {
	if(self = [super init]) {
		keys = [[NSMutableArray alloc] init];
		m_connector = [connector retain];
		name = [nameVal retain];
		subPath = [pathVal retain];
		m_marker = mark;
		m_increment = mx;
		hasMore = YES;
	}
	return self;
}

- (void)dealloc {
	[keys release], keys = nil;
	[name release], name = nil;
	[subPath release], subPath = nil;
	[m_connector release], m_connector = nil;
	[super dealloc];
}

#pragma mark -

- (NSString*)name {
	return name;
}

- (NSString*)subPath {
	return subPath;
}

- (NSArray*)keys {
	return keys;
}

- (void)setHasMore:(BOOL)more {
	hasMore = more;
}

- (BOOL)hasMore {
	return hasMore;
}

- (BOOL)fetchNext {
	return [m_connector m_fetchNext:self];
}

@end
