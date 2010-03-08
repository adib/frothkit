//
//  MemcachedConnector.h
//  FrothKit
//
//  Created by Allan Phillips on 05/02/10.
//  Copyright 2010 Thinking Code Software Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <libmemcached/memcached.h>

/*!
	\brief [Experimental] Simplified cocoa wrapper around libmemcached for memcached access from web applications. Expect it to change.
 
	TODO: 
	- better error handling and logging
	- better seralization support
 */
@interface MemcachedConnector : NSObject {
	memcached_st *memc;
}

/*!
	\brief Returns a shared connection created with a server list from a Memcached.plist in the apps resources
 
	The Memcached.plist should be included in the bundle's resources. The configeration file at the top level should contain a 'Servers' key value
	where the value is a Array of dictionaries representing each memcached server to add to the memcached server list. 
	The dictionary's key/values are as follows
	
	- Host = The IP of the server
	- Port = (Optional) An alternate port number the memcached server is listening on (if left out, defualt: is 11211).
*/
+ (id)sharedConnector;

/*!
	\brief Adds a server to the pool of memcached servers for the connector
	\return		If the server add was successfull
	\param host The hostname of the memcached server
	\param port	The port of the memcached server (or -1 for defualt 11211)
	\param errMsgPointer A Pointer to an error message if return is not true
*/
- (BOOL)addServer:(NSString*)host port:(int)port error:(NSString**)errMsgPointer;

/*!
	\brief Sets a cache key/value combination with no timout
	\param value Must be seralizable/deseralizable NSString, NSDate, NSArray, NSDictionary
	\param key The key for storing value to memchached.
*/
- (void)setValue:(id)value forKey:(NSString*)key;

/*!
	\brief Sets a cache key/value combinition with optional timout
	\param value Must be seralizable/deseralizable NSString, NSDate, NSArray, NSDictionary
	\param key The key for storing value to memchached.	
	\param interval An optional expireation time interval in seconds since unix epoch
 */
- (void)setValue:(id)value forKey:(NSString*)key expires:(NSTimeInterval)interval;

//- (void)addValue:(id)value forKey:(NSString*)key;
//- (void)replaceValue:(id)value forKey:(NSString*)key;

- (void)appendValue:(id)value forKey:(NSString*)key;
- (void)prependValue:(id)value forKey:(NSString*)key;

/*!
	\brief Returns the value for a given key
 */
- (id)valueForKey:(NSString*)key;

/*!
	\brief Provides a multi get from memcached. 
 
	Where larger datasets need to be returned at once, this method provides
	better performance.
 */
- (NSDictionary*)valuesForKeys:(NSArray*)keys;

- (int)incrementKey:(NSString*)key by:(unsigned int)offset;
- (int)incrementKey:(NSString*)key;

- (int)decrementKey:(NSString*)key by:(unsigned int)offset;
- (int)decrementKey:(NSString*)key;

@end
