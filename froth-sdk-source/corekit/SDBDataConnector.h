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
#import "sdb.h"

/*! 
	\brief		Provides an Objective-C Wrapper around libSDB for SimpleDB Connections 
			
				Response data is formated as plain foundation objects.
				Array or results:	NSArray.
				Result Item:		NSDictionary {"itemName":{"key1":"value","key2":"value"}"itemTwoNAme...}
  
				<br><br>
				<b>DataSource.plist keys required.<b><br>
				<br>account: The amazon sdb account
				<br>secret:	The secret
  */
@interface SDBDataConnector : NSObject {
	struct SDB* sdb;
	
	BOOL m_asMulti;
	NSMutableDictionary* m_asMultiResultData;
}

/*! \brief Returns a shared connector "only" shared with the current thread, each thread gets a new one */
+ (SDBDataConnector*)sharedDataConnectorForAccount:(NSString*)account secret:(NSString*)secret;

- (id)initWithAccount:(NSString*)accountKey secret:(NSString*)accountSecret;

- (void)deleteAllItemsForDomain:(NSString*)domain;

/*! \brief Returns if self is currently accumulating operations for a endMultiOperations commit */
- (BOOL)inMultiMode;

/*! \brief Begins a multiple operation mode. no writes/selects are actually triggered until a corresponding -endMultiOperations */
- (void)beginMultiOperations;

/*! \brief Finalizes all the operations and executes them. Upon completion, returns and populates the -(NSDictionary*)multiResults dictionary */
- (void)endMultiOperations;

/*! \brief Returns the results of the operations. Domains are defined as the based keys, as well as statistic information. */ 
- (NSDictionary*)multiResults;

// ---- Accessors ----- //

//The attributes value as return
- (NSString*)getAttribute:(NSString*)key forItem:(NSString*)item inDomain:(NSString*)domain;

//NSDictionary of key/value attributes -> "key":"value"
- (NSDictionary*)getAttributes:(NSArray*)keysArray forItem:(NSString*)item inDomain:(NSString*)domain;

//Gets all attributes for a item (VERY FAST!)
- (NSDictionary*)getAttributesForItem:(NSString*)item inDomain:(NSString*)domain;

//Array of item NSDictionarties (See notes) for the select * from domain where ... select query
- (NSArray*)getItemsWithSelect:(NSString*)selectQuery;

// ---- Setters ---- //

//Put/Replace a single attribute in an item
- (void)setValue:(NSString*)value forKey:(NSString*)key forItem:(NSString*)item inDomain:(NSString*)domain;
- (void)replaceValue:(NSString*)value forKey:(NSString*)key forItem:(NSString*)item inDomain:(NSString*)domain;

//Put/Replace multiple attributes in an item, also used to create an item
- (void)setValues:(NSArray*)values forKeys:(NSArray*)keys forItem:(NSString*)item inDomain:(NSString*)domain;
- (void)replaceValues:(NSArray*)values forKeys:(NSArray*)keys forItem:(NSString*)item inDomain:(NSString*)domain;

//Deletes a single item and its attributes from a domain
- (void)deleteItem:(NSString*)item inDomain:(NSString*)domain;

//Deletes values based on keys?
- (void)deleteValues:(NSArray*)values forKeys:(NSArray*)keys forItem:(NSString*)item inDomain:(NSString*)domain;

//TODO: implement these methodds
- (void)deleteValue:(NSString*)value forKey:(NSString*)key forItem:(NSString*)item inDomain:(NSString*)domain;
- (void)deleteKey:(NSString*)key forItem:(NSString*)item inDomain:(NSString*)domain;

@end
