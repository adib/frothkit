//
//  SDBDataConnetor.m
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

#import "SDBDataConnector.h"
#import "Froth+Exceptions.h"

#import <stdlib.h>
#include <pthread.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/errno.h>
#include <unistd.h>

#define SHOW_STATS 1

static NSMutableDictionary* threadPool = nil;

@implementation SDBDataConnector

+ (SDBDataConnector*)sharedDataConnectorForAccount:(NSString*)account secret:(NSString*)secret {
	//Provides a seperate dataConnector per thread for concurrency
	//NSLog(@"SDBDataConnector: get for account:%@ secret:%@", account, secret);
	
	@synchronized(threadPool) {
		if(!threadPool)
			threadPool = [[NSMutableDictionary dictionary] retain];
	}

	int ti = [[[[NSThread currentThread] threadDictionary] valueForKey:@"location"] intValue];
	NSString* key = [NSString stringWithFormat:@"%i", ti];
	
	NSMutableDictionary* accountThreads = [threadPool valueForKey:account];
	if(!accountThreads) {
		accountThreads = [NSMutableDictionary dictionary];
		@synchronized(threadPool) {
			[threadPool setValue:accountThreads forKey:account];
		}
	}
	
	SDBDataConnector* forThread = [accountThreads valueForKey:key];
	if(!forThread) {
		forThread = [[SDBDataConnector alloc] initWithAccount:account secret:secret];
		@synchronized(accountThreads) {
			[accountThreads setObject:forThread forKey:key];
		}
	}
	return forThread;
}

- (id)initWithAccount:(NSString*)accountKey secret:(NSString*)accountSecret {
	if(self = [super init]) {
#if SHOW_STATS
		NSLog(@"starting up SDBDataConnector-----------------------");
#endif

		sdb_global_init();
		sdb_init(&sdb, 
				 [accountKey cStringUsingEncoding:NSUTF8StringEncoding], 
				 [accountSecret cStringUsingEncoding:NSUTF8StringEncoding]);
		
		sdb_set_retry(sdb, 5, 30);
	}
	return self;
}

- (void)dealloc {
#if SHOW_STATS
	NSLog(@"cleaning up SDBDataConnector-----------------------");
	sdb_fprint_statistics(sdb, stderr);
#endif
	sdb_destroy(&sdb);
	sdb_global_cleanup();
	[m_asMultiResultData release];
	[super dealloc];
}

- (void)runTests {	
	//Lets do a test.
	struct sdb_response* res;
	//int r = sdb_get_all(sdb, "com.notified.notification", "test", &res);
	int r = sdb_select(sdb, "select * from `com.notified.notification` where account_id like 'allan%'", &res);
	
	NSLog(@"res-code:%i size:%i", r, res->size);
	
	if(r>=0) {
		int i;
		for(i=0;i<res->size;i++) {
			NSString* itemKey = [NSString stringWithCString:res->items[i].name encoding:NSUTF8StringEncoding];
			NSLog(@"--Item:%@", itemKey);
			
			int k;
			for(k=0;k<res->items[i].size;k++) {
				NSString* key =		[NSString stringWithCString:res->items[i].attributes[k].name encoding:NSUTF8StringEncoding];
				//NSString* value =	[NSString stringWithCString:res->items[i].attributes[k].value encoding:NSUTF8StringEncoding];
				NSLog(@"--Attibute key:%@", key);
			}
		}
	}
	
	sdb_free(&res);
}

- (void)deleteAllItemsForDomain:(NSString*)domain {
	NSArray* items = [self getItemsWithSelect:[NSString stringWithFormat:@"select * from `%@` where to_id like 'allan%%'", domain]];
	for(NSDictionary* item in items) {
		[self deleteItem:[[item allKeys] lastObject] inDomain:domain];
	}
}

#pragma mark -
#pragma mark Getters

- (NSString*)getAttribute:(NSString*)key forItem:(NSString*)item inDomain:(NSString*)domain {
	struct sdb_response* res;
	NSString* attr = nil;
	if(sdb_get(sdb, 
					[domain cStringUsingEncoding:NSUTF8StringEncoding], 
					[item cStringUsingEncoding:NSUTF8StringEncoding], 
					[key cStringUsingEncoding:NSUTF8StringEncoding],
			   &res) >= 0) {
	
		int i;
		for(i=0;i<res->size;i++) {
			attr = [NSString stringWithCString:res->attributes[i].value encoding:NSUTF8StringEncoding];
		}
	}
	sdb_free(&res);
	return attr;
}

- (NSDictionary*)getAttributes:(NSArray*)keysArray forItem:(NSString*)item inDomain:(NSString*)domain {
	struct sdb_response* res;
	NSMutableDictionary* attrs = [NSMutableDictionary dictionary];
	
	int ksize = [keysArray count];
	const char* ckeys[ksize];
	int n = 0;
	for(NSString* key in keysArray) {
		ckeys[n] = [key cStringUsingEncoding:NSUTF8StringEncoding];
		n++;
	}
	if(sdb_get_many(sdb, 
			   [domain cStringUsingEncoding:NSUTF8StringEncoding], 
			   [item cStringUsingEncoding:NSUTF8StringEncoding],
			   (size_t)ksize,
			   ckeys,	//Array of char arrays
			   &res) >= 0) {
		
		int i;
		for(i=0;i<res->size;i++) {
			NSString* name =	[[NSString alloc] initWithCString:res->attributes[i].name encoding:NSUTF8StringEncoding];
			NSString* value =	[[NSString alloc] initWithCString:res->attributes[i].value encoding:NSUTF8StringEncoding];
			
			//Handle multi value support
			if([attrs.allKeys containsObject:name]) {
				id orgValue = [attrs valueForKey:name];
				if([orgValue isKindOfClass:[NSArray class]]) {
					[(NSMutableArray*)orgValue addObject:value];
				} else {
					NSMutableArray* arr = [NSMutableArray arrayWithObject:orgValue];
					[arr addObject:value];
					[attrs setObject:arr forKey:name];
				}
			} else {
				[attrs setObject:value forKey:name];
			}
		}
	}
	sdb_free(&res);
	return attrs;
}

- (NSDictionary*)getAttributesForItem:(NSString*)item inDomain:(NSString*)domain {
	struct sdb_response* res;
	NSMutableDictionary* attrs = [NSMutableDictionary dictionary];
	
	if(sdb_get_all(sdb, 
					[domain cStringUsingEncoding:NSUTF8StringEncoding], 
					[item cStringUsingEncoding:NSUTF8StringEncoding],
					&res) >= 0) {
		
		int i;
		for(i=0;i<res->size;i++) {
			NSString* name =	[[NSString alloc] initWithCString:res->attributes[i].name encoding:NSUTF8StringEncoding];
			NSString* value =	[[NSString alloc] initWithCString:res->attributes[i].value encoding:NSUTF8StringEncoding];
			
			//Handle multi value support
			if([attrs.allKeys containsObject:name]) {
				id orgValue = [attrs valueForKey:name];
				if([orgValue isKindOfClass:[NSArray class]]) {
					[(NSMutableArray*)orgValue addObject:value];
				} else {
					NSMutableArray* arr = [NSMutableArray arrayWithObject:orgValue];
					[arr addObject:value];
					[attrs setObject:arr forKey:name];
				}
			} else {
				[attrs setObject:value forKey:name];
			}
		}
	}
	sdb_free(&res);
	return attrs;
}

- (NSArray*)getItemsWithSelect:(NSString*)selectQuery {
	struct sdb_response* res;
	NSMutableArray* items = [NSMutableArray array];
	
	if(sdb_select(sdb, [selectQuery cStringUsingEncoding:NSUTF8StringEncoding], &res) >= 0) {
		int i;
		for(i=0;i<res->size;i++) {
			
			NSString* itemKey = [NSString stringWithCString:res->items[i].name encoding:NSUTF8StringEncoding];
			
			NSMutableDictionary* attrs = [NSMutableDictionary dictionary];
			
			//Get attributes for item
			int k;
			for(k=0;k<res->items[i].size;k++) {
			
				NSString* name =	[[NSString alloc] initWithCString:res->items[i].attributes[k].name encoding:NSUTF8StringEncoding];
				NSString* value =	[[NSString alloc] initWithCString:res->items[i].attributes[k].value encoding:NSUTF8StringEncoding];
				//Handle multi value support
				if([attrs.allKeys containsObject:name]) {
					id orgValue = [attrs valueForKey:name];
					if([orgValue isKindOfClass:[NSArray class]]) {
						[(NSMutableArray*)orgValue addObject:value];
					} else {
						NSMutableArray* arr = [NSMutableArray arrayWithObject:orgValue];
						[arr addObject:value];
						[attrs setObject:arr forKey:name];
					}
				} else {
					[attrs setObject:value forKey:name];
				}
				
			}
			
			//Add the item to the items array
			[items addObject:[NSDictionary dictionaryWithObject:attrs forKey:itemKey]];
		}
	}
	sdb_free(&res);
	return items;
}

#pragma mark Setters

- (void)setValue:(NSString*)value forKey:(NSString*)key forItem:(NSString*)item inDomain:(NSString*)domain {
	if(!m_asMulti) {
		int r = sdb_put(sdb, 
						[domain cStringUsingEncoding:NSUTF8StringEncoding],
						[item cStringUsingEncoding:NSUTF8StringEncoding],
						[key cStringUsingEncoding:NSUTF8StringEncoding],
						[value cStringUsingEncoding:NSUTF8StringEncoding]);
		if(r < 0) {
			NSLog(@"*** SDBDataConnector - error for setValue: [%i]", r);
		}	
	} else {
		sdb_multi res = sdb_multi_put(sdb, 
									  [domain cStringUsingEncoding:NSUTF8StringEncoding],
									  [item cStringUsingEncoding:NSUTF8StringEncoding],
									  [key cStringUsingEncoding:NSUTF8StringEncoding],
									  [value cStringUsingEncoding:NSUTF8StringEncoding]);
		if(res == SDB_MULTI_ERROR) {
			NSLog(@"*** SDBDataConnector - error for multi setValue");
		}
	}
}

- (void)replaceValue:(NSString*)value forKey:(NSString*)key forItem:(NSString*)item inDomain:(NSString*)domain {
	if(!m_asMulti) {
		int r = sdb_replace(sdb, 
						[domain cStringUsingEncoding:NSUTF8StringEncoding],
						[item cStringUsingEncoding:NSUTF8StringEncoding],
						[key cStringUsingEncoding:NSUTF8StringEncoding],
						[value cStringUsingEncoding:NSUTF8StringEncoding]);
		
		if(r < 0) {
			NSLog(@"*** SDBDataConnector - error for setValue: [%i]", r);
		}
	} else {
		sdb_multi res = sdb_multi_replace(sdb, 
										  [domain cStringUsingEncoding:NSUTF8StringEncoding],
										  [item cStringUsingEncoding:NSUTF8StringEncoding],
										  [key cStringUsingEncoding:NSUTF8StringEncoding],
										  [value cStringUsingEncoding:NSUTF8StringEncoding]);
		if(res == SDB_MULTI_ERROR) {
			NSLog(@"*** SDBDataConnector - error for multi setValue");
		}
	}
}

- (void)setValues:(NSArray*)values forKeys:(NSArray*)keys forItem:(NSString*)item inDomain:(NSString*)domain {
	
	int ksize = [keys count];
	int vsize = [values count];
	if(ksize != vsize) {
		NSLog(@"*** SDBDataConnector - setValues: Sizes must match for values and keys in set");
	}
	
	const char* ckeys[ksize];
	int n = 0;
	for(NSString* key in keys) {
		ckeys[n] = [key cStringUsingEncoding:NSUTF8StringEncoding];
		n++;
	}
	
	const char* cvalues[ksize];
	n = 0;
	for(NSString* value in values) {
		cvalues[n] = [value cStringUsingEncoding:NSUTF8StringEncoding];
		n++;
	}
	
	if(!m_asMulti) {
		int r = sdb_put_many(sdb, 
						[domain cStringUsingEncoding:NSUTF8StringEncoding],
						[item cStringUsingEncoding:NSUTF8StringEncoding],
						(size_t)ksize,
						ckeys,
						cvalues);
		
		if(r < 0) {
			NSLog(@"*** SDBDataConnector - error for setValues: [%i]", r);
		}
	} else {
		sdb_multi r = sdb_multi_put_many(sdb, 
							 [domain cStringUsingEncoding:NSUTF8StringEncoding],
							 [item cStringUsingEncoding:NSUTF8StringEncoding],
							 (size_t)ksize,
							 ckeys,
							 cvalues);
		
		if(r == SDB_MULTI_ERROR) {
			NSLog(@"*** SDBDataConnector - error for multi setValues");
		}
	}
}

- (void)replaceValues:(NSArray*)values forKeys:(NSArray*)keys forItem:(NSString*)item inDomain:(NSString*)domain {
	
	int ksize = [keys count];
	int vsize = [values count];
	if(ksize != vsize) {
		NSLog(@"*** SDBDataConnector - replaceValues: Sizes must match for values and keys in set");
	}
	
	const char* ckeys[ksize];
	int n = 0;
	for(NSString* key in keys) {
		ckeys[n] = [key cStringUsingEncoding:NSUTF8StringEncoding];
		n++;
	}
	
	const char* cvalues[ksize];
	n = 0;
	for(NSString* value in values) {
		cvalues[n] = [value cStringUsingEncoding:NSUTF8StringEncoding];
		n++;
	}
	
	if(!m_asMulti) {
		int r = sdb_replace_many(sdb, 
							 [domain cStringUsingEncoding:NSUTF8StringEncoding],
							 [item cStringUsingEncoding:NSUTF8StringEncoding],
							 (size_t)ksize,
							 ckeys,
							 cvalues);
		
		if(r < 0) {
			NSLog(@"*** SDBDataConnector - error for replaceValues: [%i]", r);
		}
	} else {
		sdb_multi r = sdb_multi_replace_many(sdb, 
										 [domain cStringUsingEncoding:NSUTF8StringEncoding],
										 [item cStringUsingEncoding:NSUTF8StringEncoding],
										 (size_t)ksize,
										 ckeys,
										 cvalues);
		
		if(r == SDB_MULTI_ERROR) {
			NSLog(@"*** SDBDataConnector - error for multi replaceValues");
		}
	}
}

- (void)deleteItem:(NSString*)item inDomain:(NSString*)domain {
	if(sdb_delete_item(sdb, [domain cStringUsingEncoding:NSUTF8StringEncoding], [item cStringUsingEncoding:NSUTF8StringEncoding]) < 0) {
		NSLog(@"*** SDBDataConnector - Failure to delete item [%@] from domain [%@]", item, domain);
	}
}

- (void)deleteValue:(NSString*)value forKey:(NSString*)key forItem:(NSString*)item inDomain:(NSString*)domain {
	froth_exception(@"APIMethodNotYetImplementedException", @"-deleteValue:forKey:forItem:inDomain: Is not implemented yet");
}

- (void)deleteValues:(NSArray*)values forKeys:(NSArray*)keys forItem:(NSString*)item inDomain:(NSString*)domain {
	int ksize = [keys count];
	int vsize = [values count];
	if(ksize != vsize) {
		NSLog(@"*** SDBDataConnector - replaceValues: Sizes must match for values and keys in set");
	}
	
	const char* ckeys[ksize];
	int n = 0;
	for(NSString* key in keys) {
		ckeys[n] = [key cStringUsingEncoding:NSUTF8StringEncoding];
		n++;
	}
	
	const char* cvalues[ksize];
	n = 0;
	for(NSString* value in values) {
		cvalues[n] = [value cStringUsingEncoding:NSUTF8StringEncoding];
		n++;
	}
	
	int r = sdb_delete_many(sdb, 
							 [domain cStringUsingEncoding:NSUTF8StringEncoding],
							 [item cStringUsingEncoding:NSUTF8StringEncoding],
							 (size_t)ksize,
							 ckeys,
							 cvalues);
	
	if(r < 0) {
		NSLog(@"*** SDBDataConnector - error for replaceValues: [%i]", r);
	}
}

- (void)deleteKey:(NSString*)key forItem:(NSString*)item inDomain:(NSString*)domain {
}

#pragma mark -
#pragma mark Multi Action Support

- (BOOL)inMultiMode {
	return m_asMulti;
}

- (void)beginMultiOperations {
	m_asMulti = YES;
}

/*
	Currently only write operations are supported.
 */
- (void)endMultiOperations {
	if(!m_asMulti) 
		return;
	
	m_asMulti = NO;
	
	struct sdb_multi_response* multi_res;
	
	int r = sdb_multi_run(sdb, &multi_res);
	if(r<0) {
		NSLog(@"SDBDataConnector [ERROR]-endMultiOperations. Error %i", r);
	} else {
		//NSLog(@"do something with the results");
	}
	sdb_multi_free(&multi_res);
	
}

- (NSDictionary*)multiResults {
	return m_asMultiResultData;
}

@end
