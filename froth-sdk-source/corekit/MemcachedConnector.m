//
//  MemcachedConnector.m
//  FrothKit
//
//  Created by Allan Phillips on 05/02/10.
//  Copyright 2010 Thinking Code Software Inc. All rights reserved.
//

#import "MemcachedConnector.h"
#import "JSON.h"
//http://docs.tangent.org/libmemcached/

static MemcachedConnector* _sharedServersConnector = nil;

@implementation MemcachedConnector

+ (void)runTest {
	
	memcached_st *memc;
	memcached_server_st * servers;
	memcached_return_t rc;
	memc = memcached_create(NULL);
	
	//single server for test.
	servers = memcached_server_list_append(NULL, [@"localhost" UTF8String], 11211, &rc);
	if(rc) {
		NSLog(@"[[MemcachedConnector memcached_server_list_append]] error is :%@", [NSString stringWithUTF8String:memcached_strerror(memc, rc)]);
	} else {
		memcached_server_push(memc, servers);
	}
	
	NSString* key = @"test-key";
	
	size_t rl;
	uint32_t flags;
	
	//Test get: first run is null so we do the test-key set.
	char* results = memcached_get(memc, [key UTF8String], [key length], &rl, &flags, &rc); 
	if(rc) {
		NSLog(@"[[MemcachedConnector test]] error is :%@", [NSString stringWithUTF8String:memcached_strerror(memc, rc)]);
	}
	if(results != NULL) {
		NSLog(@"[[MemcachedConnector test]] -- Get results from server:%@", [[NSString alloc] initWithBytes:results length:rl encoding:NSUTF8StringEncoding]);
	} else {
		//set the key to memcache
		
		NSString* value = @"This is a simple test value";
		memcached_set(memc, [key UTF8String], [key length], [value UTF8String], [value length], (time_t)0, (uint32_t)0);
		
		NSLog(@"[[MemcachedConnector test]] -- Setting 'test-key' value");
	}
	
	memcached_free(memc);
}

#pragma mark -

- (id)init {
	if(self = [super init]) {
		memc = memcached_create(NULL);
	}
	return self;
}

- (void)dealloc {
	memcached_free(memc);
	[super dealloc];
}

/* 
	Parse the memcached server list from the Memcached.plist file and sets up the memcached_st pointer
*/
- (void)prepareServersFromConfigurationDictionary {
	//Get the memcached servers, if non we will attempt to use 'localhost' : '11211'
	NSString* mconf = [NSString stringWithFormat:@"%@/Contents/Resources/Memcached.plist", [[NSBundle mainBundle] bundlePath]];
	NSDictionary* mconfDict = [[NSDictionary dictionaryWithContentsOfFile:mconf] retain]; //?? retain?
	
	NSArray* servers; //array of dictionarys with Host and Port(optional)
	if(!mconfDict) {
		NSLog(@"Useing localhost for memcache...");
		servers = [NSArray arrayWithObject:[NSDictionary dictionaryWithObject:@"localhost" forKey:@"Host"]];
	} else {
		servers = [mconfDict valueForKey:@"Servers"];
	}
	
	for(NSDictionary* server in servers) {
		int port = -1;
		if([[server allKeys] containsObject:@"Port"]) {
			port = [[server objectForKey:@"Port"] intValue];
		}
		[self addServer:[server valueForKey:@"Host"] port:port error:nil];
	}
}

+ (id)sharedConnector {
	if(!_sharedServersConnector) {
		_sharedServersConnector = [[self alloc] init];
		[_sharedServersConnector prepareServersFromConfigurationDictionary];
	}
	return _sharedServersConnector;
}

#pragma mark -
#pragma mark Shared

- (void)handleReturnError:(memcached_return_t)rc forKey:(NSString*)key {
	NSLog(@"[MemcachedConnector LogError:] error key:[%@] :%@", key, [NSString stringWithUTF8String:memcached_strerror(memc, rc)]);
}

#pragma mark -
#pragma mark Server Operations

- (BOOL)addServer:(NSString*)host port:(int)port error:(NSString**)errMsgPointer {
	if(host && host.length > 0) {
		memcached_return_t rt;
		rt = memcached_server_add(memc, [host UTF8String], (in_port_t)(port>0?port:11211));
		if(!rt) 
			return TRUE; 	
		else {
			*errMsgPointer = [NSString stringWithUTF8String:memcached_strerror(memc, rt)];
			return FALSE;
		}
	}
	*errMsgPointer = @"[MemcachedConnector] Invalid host name";
	return FALSE;
}

#pragma mark -
#pragma mark Value Operations

- (void)setValue:(id)value forKey:(NSString*)key {
	[self setValue:value forKey:key expires:0];
}

- (void)setValue:(id)value forKey:(NSString*)key expires:(NSTimeInterval)interval {
	memcached_return_t rc;
	
	NSString* storableValue;
	if([value isKindOfClass:[NSString class]]) {
		storableValue = value;
	} else {
		NSString* json = [value JSONRepresentation];
		if(json) {
			storableValue = json;
		} else {
			NSLog(@"[MemcachedConnector setValue:forKey:] error: Value not seralizable");
			return;
		}
	}
	
	rc = memcached_set(memc, [key UTF8String], [key length], [storableValue UTF8String], [storableValue length], (time_t)interval, (uint32_t)0);
	if(rc) {
		[self handleReturnError:rc forKey:key];
	}
}

- (void)addValue:(id)value forKey:(NSString*)key {
	
}

- (void)replaceValue:(id)value forKey:(NSString*)key {
	
}

- (void)appendValue:(id)value forKey:(NSString*)key {
	memcached_return_t rc;
	
	NSString* storableValue;
	if([value isKindOfClass:[NSString class]]) {
		storableValue = value;
	} else {
		NSString* json = [value JSONRepresentation];
		if(json) {
			storableValue = json;
		} else {
			NSLog(@"[MemcachedConnector setValue:forKey:] error: Value not seralizable");
			return;
		}
	}
	
	rc = memcached_append(memc, [key UTF8String], [key length], [storableValue UTF8String], [storableValue length], (time_t)0, (uint32_t)0);
	if(rc) {
		[self handleReturnError:rc forKey:key];
	}
}

- (void)prependValue:(id)value forKey:(NSString*)key {
	memcached_return_t rc;
	
	NSString* storableValue;
	if([value isKindOfClass:[NSString class]] && [value length] > 0) {
		storableValue = value;
	} else if(value) {
		NSString* json = [value JSONRepresentation];
		if(json) {
			storableValue = json;
		} else {
			NSLog(@"[MemcachedConnector setValue:forKey:] error: Value not seralizable");
			return;
		}
	} else {
		NSLog(@"[MemcachedConnector setValue:forKey:] error: Value not nil");
	}
	
	rc = memcached_prepend(memc, [key UTF8String], [key length], [storableValue UTF8String], [storableValue length], (time_t)0, (uint32_t)0);
	if(rc) {
		[self handleReturnError:rc forKey:key];
	}
}

/*!
 \brief Returns the value for a given key
 */
- (id)valueForKey:(NSString*)key {	
	memcached_return_t rc;
	size_t rl;
	uint32_t flags;
	
	char* results = memcached_get(memc, [key UTF8String], [key length], &rl, &flags, &rc);
	if(!rc && results) {
		return [[[NSString alloc] initWithBytes:results length:rl encoding:NSUTF8StringEncoding] autorelease];
	} else if(rc) {
		[self handleReturnError:rc forKey:key];
	}
	return nil;
}

/*!
 \brief Provides a multi get from memcached. 
 
 Where larger datasets need to be returned at once, this method provides
 better performance.
 */
- (NSDictionary*)valuesForKeys:(NSArray*)keys {
	return nil;
}

- (int)incrementKey:(NSString*)key by:(unsigned int)offset {
	memcached_return_t rc;
	uint64_t inc;
	
	rc = memcached_increment(memc, [key UTF8String], [key length], (offset),  &inc);
	if(!rc) {
		return (int)inc;
	} else if(rc == MEMCACHED_NOTFOUND) {
		[self setValue:@"1" forKey:key];
		return 1;
	}

	[self handleReturnError:rc forKey:key];
	return NSNotFound;
}

- (int)incrementKey:(NSString*)key {
	return [self incrementKey:key by:1];
}

- (int)decrementKey:(NSString*)key by:(unsigned int)offset {
	memcached_return_t rc;
	uint64_t inc;
	
	rc = memcached_decrement(memc, [key UTF8String], [key length], (offset),  &inc);
	if(!rc)
		return (int)inc;
	
	[self handleReturnError:rc forKey:key];
	return NSNotFound;
}


- (int)decrementKey:(NSString*)key {
	return [self decrementKey:key by:1];
}

@end
