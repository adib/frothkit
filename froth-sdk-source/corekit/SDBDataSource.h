//
//  SDBDataSource.h
//  Froth
//
//  Created by Allan Phillips on 12/09/09.
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
#import "WebDataSource.h"
#import "SDBDataConnector.h"

/*!
	\brief	Provides an Amazon SimpleDB DataSource. And an optional memcached layer.
				
				SDBDataSources dont make any assumption of data type. It also
				allow for a DataType of "NSArray" that is used for multiple attributes as a feature
				supported by Amazon Simpledb.
 
				Applications can enable the memcache integration with DS key UseMemcached = YES
 
				The main issue with simpledb is their no way of getting the datatype for a request. And since the
				data source has no knowledge of WebDataSource subclasses, SDB adds a catagory to WebModelBase
				that provides a "base" implementation.
		
				<h3>SDBDataSource Conditions Support</h3>
				SDBDataSource support the conditional selects with the optional key names of every(`key`) for keys
				in the condition dictionary. For details on the every condition see here. <br>
				<a href="http://docs.amazonwebservices.com/AmazonSimpleDB/latest/DeveloperGuide/RangeValueQueriesSelect.html">Amazon Range Value Queries</a>
 
				Changes:
				
 */
@interface SDBDataSource : NSObject <WebDataSource> {
	BOOL		_memcachedEnabled;
	BOOL		_asTransaction;
	NSString*	_awsAccount;
	NSString*	_awsSecret;
}

@end

/*!
	\brief	Provides WebModelBase type schema definitions for proper read/write to schema-less sdb
	\detail WebModelBase + SDBDataSource adds the ability to add multiple values per key as supported
				by amazon simple db.
 
				<h3>Type Defining</h3>
				Becouse simpledb is a typeless database, WebModelBase subclasses must implement class methods
				that return the type of property, These must be implemented for all types other then NSStrings.
				<br><br>
				+ (NSNumber*)dataTypeFor&#60;Key&#62;
				<br><br>
				<i>For example..</i>
<pre>
+ (NSNumber*)dataTypeForCreated {
	return [NSNumber numberWithInt:7];
}
</pre>
				<h3>Data Types</h3>
				<ul>
				<li>0 - STRING
				<li>1 - FLOAT
				<li>2 - BOOL
				<li>3 - INT
				<li>5 - ARRAY/LIST
				<li>7 - TIMESTAMP
				</ul>
 
				Currenlty only NSString values are supported for multi value options
 */
@interface WebModelBase (SDBDataSource)

/*! \brief	Provides support for adding a multiple values for a key.
	\detail	Currently the key sepcified type must be "NSArray" */
- (void)addValue:(id)value forKey:(NSString*)key;

/*! \brief	Provides support for removing a multiple values for a key.
	\detail	Currently the key sepcified type must be "NSArray" */
- (void)removeValue:(id)value forKey:(NSString*)key;

//TODO: Implement this
- (void)addValues:(NSArray*)values forKey:(NSString*)key;

//See sceala types for info.
//0 - STRING
//1 - FLOAT
//2 - BOOL
//3 - INT
//7 - TIMESTAMP
//5 - ARRAY
//+ (NSNumber*)dataTypeFor<Key>

@end
