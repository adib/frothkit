//
//  MemoryDataSource.m
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

#import "MemoryDataSource.h"
#import "MemcachedConnector.h"
#import "Froth+Defines.h"
#import "JSON.h"

/*
	Objects are internally stored in the object dictionary with the following structure
	dictionary-key = Model:Key value = object
 */
@implementation MemoryDataSource

/*
	These provides thread safe access to the session. As it needs to be shared on all threads
	This is ok, as only one connection typically modifies a single object
 */

- (id <WebDataSource>)initWithOptions:(NSDictionary*)options {
	if(self = [super init]) {
		m_memory_storage = [[NSMutableDictionary dictionary] retain];
		_memcachedEnabled = [[options valueForKey:@"UseMemcached"] boolValue];
		if(_memcachedEnabled) {
			NSLog(@"--- MemoryDataSource using memcache ---");
		}
	}
	return self;
}

- (NSString*)_memoryKeyForObject:(id)object {
	return [NSString stringWithFormat:@"%@:%@", [[object class] modelName], [object valueForKey:[[object class] identifierName]]];
}

- (BOOL)createObject:(WebModelBase*)object {
	if(_memcachedEnabled) {
		NSArray* dirtyKeys = [object dirtyKeys];
		NSString* objkey = [self _memoryKeyForObject:object];
		for(NSString* key in dirtyKeys) {
			NSString* nkey = froth_str(@"%@:%@", objkey, key);
			[[MemcachedConnector sharedConnector] setValue:[object valueForKey:key] forKey:nkey];
		}
		
		//Create the key table
		[[MemcachedConnector sharedConnector] setValue:[[object data] allKeys] forKey:objkey];
	} else {
		@synchronized(m_memory_storage) {
			[m_memory_storage setObject:object forKey:[self _memoryKeyForObject:object]];
		}
	}
	return YES;
}

- (BOOL)updateObject:(WebModelBase*)object {
	[self createObject:object];
	return YES;
}

- (BOOL)deleteObject:(WebModelBase*)object {
	if(_memcachedEnabled) {
		//TODO...
	} else {
		@synchronized(m_memory_storage) {
			[m_memory_storage removeObjectForKey:[self _memoryKeyForObject:object]];
		}
	}
	return YES;
}

- (id)getObjectOfModel:(Class)aModelClass withIdentifier:(id)identifier {
	
	if(!identifier) {
		return nil;
	}
	
	NSString* key = [NSString stringWithFormat:@"%@:%@", [aModelClass modelName], identifier];
	if(_memcachedEnabled) {
		NSString* kTable = [[MemcachedConnector sharedConnector] valueForKey:key];
		if(kTable) {
			WebModelBase* obj = [[aModelClass alloc] initFromDatabase];
			[obj setValue:identifier forKey:[aModelClass identifierName]];
			
			NSArray* keys = [kTable JSONValue];
			
			for(NSString* okey in keys) {
				NSString* nkey = froth_str(@"%@:%@", key, okey);
				NSString* value = [[MemcachedConnector sharedConnector] valueForKey:nkey];
				
				//Auto deseralize if seralized.
				id valueObj = [value JSONValue];
				if(!valueObj) {
					valueObj = value;
				}
				
				[obj setValue:valueObj forUndefinedKey:okey];
			}
			
			[obj makeClean];
			return obj;
		} 
		return nil;
	} else {
		id object = [m_memory_storage objectForKey:key];
		return object;
	}
}

- (id)get:(ResultType)firstOrAll forObjectModel:(Class)aModelClass withConditions:(NSDictionary*)conditions {
	//TODO: Non Supported Method
	return nil;
}

- (NSArray*)getObjectsOfModel:(Class)aModelClass withDataSourceQuery:(NSString*)dataSourceSpecificData {
	//TODO: Non Supported Method
	return nil;
}

- (void)dealloc {
	[m_memory_storage release];
	[super dealloc];
}

- (void)beginTransaction:(NSString*)modelName {}
- (id)endTransaction:(NSString*)modelName { return nil; }

@end
