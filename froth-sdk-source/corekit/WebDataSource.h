//
//  WebDataSource.h
//  Froth
//
//  Created by Allan Phillips on 14/07/09.
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
#import "WebModelBase.h"

typedef enum {
	ResultAll = 1,
	ResultFirst = 2,
	ResultLast = 3,
	ResultCount = 4
} ResultType;

/*! \brief DataSource protocal for custom datasources connectors */
@protocol WebDataSource <NSObject>

/*!
	\brief	The defualt initializer for data sources. 
	\detail	The options dictionary contains the application
				data source options as define by its "DataSources.plist" configuration.
				
				for example se defualy DataSource.plist for example webApp
				DataSources.plist
*/				
- (id <WebDataSource>)initWithOptions:(NSDictionary*)theOptions;

//- (BOOL)writeOneValue:(id)value forKey:(NSString*)key toWritableObject(void*)obj;
//- (id)readOneValue:(void*)refValue forKey:(NSString*)key;

/*! 
	\brief	Returns boolean indicating success of created object
	\detail	Typically the properties are a kvo compatible object
				that could be a NSDictionary, or simply an actual model
				object that has properties.
	
				The WebModelBase implements -allKeys that enables
				the implementing datasource to iterate through all
				persistable keys
 
				- (NSArray*)allKeys that returns all persistable keys this
				allows implementing classes to lookup the key/value combinations
				
				Persistable key's values should be gaurinteed to be
				NSNumber, NSString, NSData..
*/
- (BOOL)createObject:(WebModelBase*)object;

/*!
	\brief	Updates a given object and returns sucess as boolean
*/
- (BOOL)updateObject:(WebModelBase*)object;

/*!
	\brief	Deletes a given object using the given identifier (ie primary key)
 */
- (BOOL)deleteObject:(WebModelBase*)object;

/*!
	\brief	Returns a single propertiesable object with the given identifier (Must be autoreleased)
 */
- (id)getObjectOfModel:(Class)aModelClass withIdentifier:(id)identifier;

/*!
	\brief	Returns a object/array/nil based on the params
	@param		firstOrAll	Could be one of count, (NSNumber), first, last, all, page
	@param		conditions	Should be a condition lookup, see example
							{ "keyName":"value",
							  "keyName":NSDictionary { "condition":"like | > | >= | between", "value":"aValue", "value2":"aValue" }
							  
							This could be complex compound lookups.
							{ "OR | AND": NSArray {... } }
						
							if conditions is nil, this method should return all, or first..
 */
- (id)get:(ResultType)firstOrAll forObjectModel:(Class)aModelClass withConditions:(NSDictionary*)conditions;

@optional
//Implementing class can implement these if they support transactions
- (void)beginTransaction:(NSString*)modelName;

/*! \brief Ends a transaction, returning any results optional to the datasource, or nil if not supported */
- (id)endTransaction:(NSString*)modelName;

/*!
	\brief	This is an optional method that datasources can implement to retrun data with a specialized query specific
				to itself. IE for MysqlDataSource this is a pure SELECT*... query
	
	\detail	See each datasource's implementation details for the details of this query
 */
- (NSArray*)getObjectsOfModel:(Class)aModelClass withDataSourceQuery:(NSString*)dataSourceSpecificData;

@end
