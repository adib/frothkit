//
//  WebModelBase+Memcache.h
//  Froth
//
//  Created by Allan Phillips on 18/09/09.
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

/*! \brief Provides powerful features for subclasses to enable memcache abilities on thier data model 
 
	1. Objects are always cached if + (BOOL)cache returns true. this includes operations
	for getByIdentifier, update, delete, and create. A md5Hash(modelname + uid) is used as the object's idenifier.
	<br><br>
	2. For convience this class adds some support for memcache features such as directly interacting with memcache store.
	<br><br>
	3. Select statements and "conditional" gets can also be cached if + (BOOL)cacheConditionals returns true. This provides for
	a powerful cacheing system for selects. Only the uid is cached for each object in the return of the select, and DataSources must
	adhear to these rules. The select statement (or conditional dictionary) is md5 hashed and used as the key for the memcache object.
	Subsiquent calls with this select will return the memcache results. These select statements must have a timeout, and the details of this
	is not yet certain for the lifespace on the cache.<br><br>
	4. To insure that select caches return any new data since the cache was made, WebModelBase implements a powerful mechanizm to allow subclasses
	to determine which object updates should get added to a select cache insureing that new calls to the select cache return new and changed objects.
	Subclassses must implement the method<br>
	+ (NSString*)cacheKeyForUpdate:(WebModelBase*) delete:(BOOL*)shouldDelete //for Create and Delete as we;;
	<br>
	Subclasses should return the cache key for the action, and retrn yes as a pointer to shouldDelete if they want to delete the cache in stead
	of update it.
	<br><br>
	<b>Notes on select caches</b><br>
	This typically only works on selects without time variable options, such as since=date wheres. In such cases, it is advisable for the select to
	be stuctured without the date, and instead have results sorted by date. Then the application layer can only return updates up to a specific date.
	Also this should work as results are typically pagenated from the backing database and the select statement anyway.
 
 */

@interface WebModelBase (Memcache)

@end
