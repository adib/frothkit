//
//  WebSession.m
//  Froth
//
//  Created by Allan Phillips on 16/07/09.
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

#import "WebSession.h"
#import "JSON.h"
#import "NSString+Utilities.h"

@implementation WebSession
@synthesize guid;
@dynamic storage;

#pragma mark -
#pragma mark WebModelBase

+ (NSString*)dataSourceName {
	return @"SessionStorage";
}

+ (NSString*)identifierName {
	return @"guid";
}
 
+ (NSArray*)hasStaticKeys {
	return NO;
}

#pragma mark -
#pragma mark WebSession

+ (WebSession*)sessionWithKey:(NSString*)sessionKey {
	return [self objectWithIdentifier:sessionKey];
}

+ (WebSession*)newSessionWithKey:(NSString*)sessionKey {
	WebSession* session = [[WebSession alloc] init];
	
	if(sessionKey)
		session.guid = sessionKey;
	
	return session; //nope. not autoreleased...
}

/*
- (void)_cacheStorageIfNeeded {
	//m_storage_elements
	if(!m_storage) {
		m_storage = [[self.storage JSONValue] retain];
	}
	
}

- (void)dealloc {
	[m_storage release];
	[guid release];
	[super dealloc];
}

#pragma mark -
#pragma mark Storage And Dynamic Method Support

- (NSArray*)storageKeys {
	[self _cacheStorageIfNeeded];
	return [m_storage allKeys];
}

- (id)valueForUndefinedKey:(NSString*)key {
	//NSLog(@"storage:%@", self.storage);
	if([self.storageKeys containsObject:key]) {
		return [m_storage objectForKey:key];
	}
	//return nil;
	return [super valueForUndefinedKey:key];
}

- (id)valueForKeyPath:(NSString*)keyPath {
	[self _cacheStorageIfNeeded];
	if([[m_storage allKeys] containsObject:[[keyPath componentsSeparatedByString:@"."] objectAtIndex:0]])
		return [m_storage valueForKeyPath:keyPath];
	else
		return [super valueForKeyPath:keyPath];
}

- (void)setValue:(id)value forUndefinedKey:(NSString*)key {
	if([[[self class] allPersistableKeys] containsObject:key] && [value respondsToSelector:@selector(JSONRepresentation)]) {
		[self _cacheStorageIfNeeded];
		NSMutableDictionary* newDictionary = [NSMutableDictionary dictionaryWithDictionary:m_storage];
		[newDictionary setObject:value forKey:key];
		[m_storage release];
		m_storage = nil;
		m_storage = [newDictionary retain];
	} else {
		[super setValue:value forUndefinedKey:key];
	}
}

- (void)removeValueForKey:(NSString*)key {
	[self _cacheStorageIfNeeded];
	NSMutableDictionary* newDictionary = [NSMutableDictionary dictionaryWithDictionary:m_storage];
	[newDictionary removeObjectForKey:key];
	[m_storage release];
	m_storage = nil;
	m_storage = [newDictionary retain];
}
 

- (BOOL)save {
	if([self deallo) {
		self.storage = [m_storage JSONRepresentation];
		return [super save];
	}
	return NO;
}
 */

@end
