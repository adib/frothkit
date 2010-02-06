//
//  MemcachedConnector.h
//  FrothKit
//
//  Created by Allan Phillips on 05/02/10.
//  Copyright 2010 Thinking Code Software Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Froth/Froth.h>

/*
	\brief This api is incomplete and still considered exparimental.
 */
@interface MemcachedConnector : NSObject {

}

/*!
	\brief Returns a shared MemcachedConnector for the given server/port
	\param The memchached server ip or domain
	\port The port memchaced is listen on, or pass -1 for defualt port.
 */
+ (id)sharedConnectorWithServer:(NSString*)server port:(int)port;
+ (id)sharedConnectorWithServer:(NSString*)server;

/*!
	\brief Sets a cache key/value combination with no timout
	\value Must be seralizable/deseralizable
*/
- (int)setValue:(id)value forKey:(NSString*)key;
- (int)setValue:(id)value forKey:(NSString*)key expires:(NSTimeInterval)interval;
- (int)addValue:(id)value forKey:(NSString*)key;
- (int)replaceValue:(id)value forKey:(NSString*)key;
- (int)appendValue:(id)value forKey:(NSString*)key;
- (int)prependValue:(id)value forKey:(NSString*)key;

/*!
	\brief Returns the value for a given key
 */
- (id)valueForKey:(id)key;

/*!
	\brief Provides a multi get from memcached. 
 
	Where larger datasets need to be returned at once, this method provides
	better performance.
 */
- (NSDictionary*)valuesForKeys:(NSArray*)keys;

@end
