//
//  MySqlDataSource.m
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

#import "MySqlDataSource.h"
#import "Froth+Exceptions.h"

@interface MySqlDataSource (Private)
- (const char *)cStringFromString:(NSString *)theString;
- (NSString *)stringWithCString:(const char *)theCString;
@end


#define SELECT_BY_ID	@"SELECT * FROM `%@` WHERE `%@` = %@ LIMIT 1"
#define INSERT_OBJECT	@"INSERT INTO `%@` (%@) VALUES (%@)"
#define UPDATE_OBJECT	@"UPDATE `%@` SET %@ WHERE (%@)"
#define DELETE_OBJECT	@"DELETE FROM `%@` WHERE (%@)"

@implementation MySqlDataSource

#pragma mark -
#pragma mark Startup and Connection

+ (void)load {
	//Required before any threads are spawned
	NSLog(@"...... mysql_library_init");
	
	//Requred for mysql
	//mysql_library_init(0, NULL, NULL);
}

//Not used foor conn/thread system
- (MYSQL*)connectWithOptions:(NSDictionary*)options {
	//this should be done on each thread, only connects if needed.
	
	//Connection details
	const char	*theLogin = [self cStringFromString:[options objectForKey:@"user"]];
	const char	*theHost =  [self cStringFromString:[options objectForKey:@"host"]];
	const char	*thePass =  [self cStringFromString:[options objectForKey:@"password"]];
	const char	*theSocket = MYSQL_UNIX_ADDR;
	const char  *theDatabase = [self cStringFromString:[options objectForKey:@"database"]];
	
	NSNumber* pn = [options objectForKey:@"port"];
	int port = 3306;
	if(pn) port = [pn intValue];
	
#if USE_THREAD_MODE
	MYSQL* mConnection = mysql_init(mConnection);
#else
	mConnection = mysql_init(mConnection);
#endif
	
	my_bool a = YES;
	
	mysql_options(mConnection,MYSQL_OPT_RECONNECT,&a);
	mConnectionFlags = CLIENT_COMPRESS;
	
	void* theConn = mysql_real_connect(mConnection, theHost, theLogin, thePass, NULL, port, theSocket, mConnectionFlags);
	if(theConn != mConnection) NSLog(@"Mysql Connection failure with error %s",  mysql_error(mConnection));
	if (mysql_select_db(mConnection, theDatabase) != 0) {
		NSLog(@"---- DSEConnection failure to select database `dse_mac`. Probably does not exist [%s]", mysql_error(mConnection));
		return NULL;
	}
	
	return mConnection;
}

//Returns a pooled connection this thread
- (MYSQL*)mConnection {
	
	//return mConnection;
	
	int ti = [[[[NSThread currentThread] threadDictionary] valueForKey:@"location"] intValue];
	
	return mpool[ti].sql;

}

- (void)lock:(BOOL)yesForLock {
	int ti = [[[[NSThread currentThread] threadDictionary] valueForKey:@"location"] intValue];
	if(yesForLock) {
		pthread_mutex_lock(&mpool[ti].lock);
	} else {
		pthread_mutex_unlock(&mpool[ti].lock);
	}
}

#pragma mark -
#pragma mark Internal

- (NSString*)sqlDataStringFromString:(NSString*)theString {
	theString = [theString stringByReplacingOccurrencesOfString:@"'" withString:@"&.sq."];
	theString = [theString stringByReplacingOccurrencesOfString:@"\"" withString:@"&.sdq."];
	return theString;
}

- (NSString*)regularStringFromSqlDataString:(NSString*)theString {
	theString = [theString stringByReplacingOccurrencesOfString:@"&.sq." withString:@"'"];
	theString = [theString stringByReplacingOccurrencesOfString:@"&.sdq." withString:@"\""];
	return theString;
}

- (const char *)cStringFromString:(NSString *)theString {	
	NSMutableData* theData;
	
	if (! theString) {
		return (const char *)NULL;
	}
	
	theData = [NSMutableData dataWithData:[theString dataUsingEncoding:mEncoding allowLossyConversion:YES]];
	[theData increaseLengthBy:1];
	return (const char *)[theData bytes];
}

- (NSString *)stringWithCString:(const char *)theCString {
	NSData* theData;
	NSString* theString;
	
	if (theCString == NULL) {
		return @"";
	}
	theData = [NSData dataWithBytes:theCString length:(strlen(theCString))];
	theString = [[NSString alloc] initWithData:theData encoding:mEncoding];
	if (theString) {
		[theString autorelease];
	}
	return theString;
}

#pragma mark -
#pragma mark MySql

void Object_SetProperty(char* theData, 
				   enum enum_field_types dataType,
				   int flags,	/*Subtype flags for bindary/text data*/
				   NSString* fieldName, 
				   WebModelBase* object,
				   NSDateFormatter* utcDateFormattter, 
				   MySqlDataSource* this) {
	
	id value = nil;
	
	//NSLog(@"next field:%@ dataType:%i", fieldName, dataType);
	
	NSString* dateFormater;
#ifdef __APPLE__
	dateFormater = @"%@ +0000";
#else
	dateFormater = @"%@ 0000";
#endif
	
	switch (dataType) {
		case MYSQL_TYPE_DATE:
		case MYSQL_TYPE_TIMESTAMP:
		case MYSQL_TYPE_DATETIME:
			value = [utcDateFormattter dateFromString:[NSString stringWithFormat:dateFormater, [NSString stringWithCString:theData]]];
			break;
		case MYSQL_TYPE_STRING:	//TEXT, CHAR, VARCHAR
		case MYSQL_TYPE_VAR_STRING:
			value = [this stringWithCString:theData];
			break;
		case MYSQL_TYPE_FLOAT:
		case MYSQL_TYPE_DOUBLE:
			value = [NSNumber numberWithFloat:[[this stringWithCString:theData] floatValue]];
			break;
		case MYSQL_TYPE_TINY:	//Also used for bools
		case MYSQL_TYPE_SHORT:
		case MYSQL_TYPE_LONG:
			value = [NSNumber numberWithInt:[[this stringWithCString:theData] intValue]];
			break;
		case MYSQL_TYPE_LONGLONG:
			value = [NSNumber numberWithInt:[[this stringWithCString:theData] longLongValue]];
			break;
		case MYSQL_TYPE_TINY_BLOB:
		case MYSQL_TYPE_MEDIUM_BLOB:
		case MYSQL_TYPE_LONG_BLOB:
		case MYSQL_TYPE_BLOB:	//BLOG, BINARY, VARBINARY, TEXT ...
			if(!(flags & BINARY_FLAG)) {
				value = [this stringWithCString:theData];
			} else {
				value = [NSData dataWithBytes:theData length:strlen(theData)];
			}
			break;
		case MYSQL_TYPE_NULL:	//NULL
			value = nil;
			break;
		default:
			break;
	}
	
	if(value) 
		[object setValue:value forKey:fieldName];
}

//May be a object, nil or array of objects
- (id)_getObjectsWithSQL:(NSString*)sql ofClass:(Class)modelClass {
	//NSLog(@"[[MySqlDataSource on-thread:%@]]", [NSThread currentThread]);
	
	NSMutableArray* results = [NSMutableArray arrayWithCapacity:100];
	
	const char *theCQuery = [self cStringFromString:sql];
	
	MYSQL* mConnection = [self mConnection];
	int theQueryCode;
	
//	[self lock:YES];
	
	if (0 == (theQueryCode = mysql_query(mConnection, theCQuery))) {	//Return code 0 indicates general success
		if (mysql_field_count(mConnection) != 0) {
			//get the objects from the result
			int fields = 0;
			int rows = 0;
			MYSQL_RES *mResult;
			/*if(mResult) {
			 mysql_free_result(mResult);
			 mResult = NULL;
			 }*/
			
			mResult = mysql_store_result(mConnection);
			if(mResult) fields = mysql_field_count(mConnection);
			if(mResult) rows = mysql_num_rows(mResult);
			
			//Get DataObjects from all rows
			unsigned long* theLengths;									//Data lenghs
			MYSQL_ROW nextRow;		
			MYSQL_FIELD* theField = mysql_fetch_field(mResult);		//fields from the result set
			
			//Model Objects keys.
			NSArray* persitableKeys = [modelClass allPersistableKeys];
			persitableKeys = [persitableKeys arrayByAddingObject:[modelClass identifierName]];
			NSDateFormatter* dateFormatter = utcDateFormattter;
			
			while(nextRow = mysql_fetch_row(mResult)) {
				theLengths = mysql_fetch_lengths(mResult);	
				if(nextRow != NULL) {
					int i, c = fields;
					
					WebModelBase* modelObject = (WebModelBase*)[[modelClass alloc] initFromDatabase];
					if(modelObject) {
						for(i = 0;i<c;i++) {
							if(nextRow[i] != NULL) {
								char *theData = calloc(sizeof(char),theLengths[i]+1);
								memcpy(theData, nextRow[i], theLengths[i]);
								theData[theLengths[i]] = '\0';
								
								NSString* fieldName = [modelClass persistableKeyForDataSourceKey:[NSString stringWithCString:theField[i].name]];
								
								if([persitableKeys containsObject: fieldName]) {
									Object_SetProperty(theData, theField[i].type, theField[i].flags, fieldName, modelObject, dateFormatter, self);
								}

								free(theData);
							}
						}
						[results addObject:modelObject];
					}
					[modelObject makeClean];
				}
			}
			mysql_free_result(mResult);
		}
	} else {
		int err = mysql_errno(mConnection);
		
		if(err == 2013) {
			//try it again recursivly until it passes, this is a bad hack!
			//return [self _getObjectsWithSQL:sql ofClass:modelClass];
		}
		
		NSLog(@"MySqlDataSource -getObjectsWithQuery: sql failure [%i][%s]\nsql [%@]", err, mysql_error(mConnection), sql);
	}
	
//	[self lock:NO];
		
	return results;
}

#pragma mark -
#pragma mark Main Thread

- (void)_setupMainThreadConnections {
	
	const char	*theLogin = [self cStringFromString:[m_connectionOptions objectForKey:@"user"]];
	const char	*theHost =  [self cStringFromString:[m_connectionOptions objectForKey:@"host"]];
	const char	*thePass =  [self cStringFromString:[m_connectionOptions objectForKey:@"password"]];
	const char	*theSocket = MYSQL_UNIX_ADDR;
	const char  *theDatabase = [self cStringFromString:[m_connectionOptions objectForKey:@"database"]];
	
	NSNumber* pn = [m_connectionOptions objectForKey:@"port"];
	int port = 3306;
	if(pn) port = [pn intValue];
	
	int i, c = kSystemThreads;
	for(i=0; i<c; i++) {
		mpool[i].sql = mysql_init(mpool[i].sql);
		
		my_bool a = YES;
		
		mysql_options(mpool[i].sql,MYSQL_OPT_RECONNECT,&a);
		mConnectionFlags = CLIENT_COMPRESS;
		
		void* theConn = mysql_real_connect(mpool[i].sql, theHost, theLogin, thePass, NULL, port, theSocket, mConnectionFlags);
		if(theConn != mpool[i].sql) NSLog(@"Mysql Connection failure with error %s",  mysql_error(mpool[i].sql));
		if (mysql_select_db(mpool[i].sql, theDatabase) != 0) {
			NSLog(@"---- DSEConnection failure to select database `dse_mac`. Probably does not exist [%s]", mysql_error(mpool[i].sql));
			continue;
		}
		
		pthread_mutex_init(&mpool[i].lock, NULL);

	}
}

#pragma mark -
#pragma mark As WebDataSource

- (id <WebDataSource>)initWithOptions:(NSDictionary*)options {
	if(self = [super init]) {
		
		@synchronized(m_connectionOptions) {
			m_connectionOptions = [options retain];
		}
		
		mEncoding = NSISOLatin1StringEncoding;
		
		//Currently for test the timeZone is local time zone
		serverTimeZone = [NSTimeZone localTimeZone];
		
		if(!serverTimeZone) froth_exception(@"LocalTimeZoneNotFound", @"Could not find timeZone for local or server tzs");
				
		//The new style universal timezone system for synchronizations
		utcDateFormattter = [[NSDateFormatter alloc] init];
#ifdef __APPLE__
		[utcDateFormattter setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];
#else
		//FIXME: We have to use old style really too bad. 
		/*	A real fix for this will be to patch Foundation.framework to use 10.4+ universal formatter styles
		 as that is more of an internation specification
		 */
		[utcDateFormattter setDateFormat:@"%Y-%m-%d %H:%M:%S %z"];
#endif
		[utcDateFormattter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
		
		[self _setupMainThreadConnections];
		
	}
	return self;
}

NSString* M_ValueForObject(id object, BOOL* asString) {
	
	if([object isKindOfClass:[NSString class]]) {
		
		*asString = YES;
		/*NSData* data = [object dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
		buffer = calloc(sizeof(char), ([data length] * 2) + 1);
		NSString* str = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
		free(buffer);*/
		return (NSString*)object;
		
	} else if([object isKindOfClass:[NSNumber class]]) {
	
		*asString = YES;
		return [(NSNumber*)object stringValue];
	
	} else if([object isKindOfClass:[NSDate class]]) {
	
		*asString = YES;
		return [(NSDate*)object description];
	
	} else if(object == [NSNull null]) {
		
		*asString = NO;
		return @"NULL";
		
	} else if([object isKindOfClass:[NSData class]]) {
		
		if([(NSData*)object length] == 0) {
			*asString = NO;
			return @"NULL";
		} else {
			//*asString = YES;
			//buffer = calloc(sizeof(char), ([(NSData*)object length] * 2) + 1);
			//NSString* str = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
			//free(buffer);
			
			return [[[NSString alloc] initWithData:object encoding:NSUTF8StringEncoding] autorelease];
		}
		
	}
	
	*asString = NO;
	return [object description];
}

- (BOOL)createObject:(WebModelBase*)object {
	NSLog(@"sql: will create new record");
	Class objectClass = [object class];
	NSString* identifierKey = [objectClass identifierName];
		
	NSMutableString* keyStr = [NSMutableString string];
	NSMutableString* valueStr = [NSMutableString string];
	
	//If the uid is null, then we assume the database will create it, so we need to get it after the update
	
	NSArray* persistables = [[object class] allPersistableKeys];
	
	BOOL isString = NO;
	BOOL hasUID = ([object valueForKey:identifierKey]==nil)?NO:YES;
	
	if(hasUID) {
		persistables = [persistables arrayByAddingObject:identifierKey];
	}
	
	NSMutableArray* nonNilKeys = [NSMutableArray array];
	for(NSString* nkey in persistables) {
		if([object valueForKey:nkey]!=nil) {
			[nonNilKeys addObject:nkey];
		}
	}
	
	
	for(NSString* key in nonNilKeys) {
		[keyStr appendFormat:@"`%@`", [objectClass dataSourceKeyForPersistableKey:key]];
		
		id nvalue = [object valueForKey:key];
		NSString* value = M_ValueForObject(nvalue, &isString);
		if([nvalue isKindOfClass:[NSData class]]) {
			[valueStr appendFormat:@"'%@'", value];	//was X'%@'
		} else {
			[valueStr appendFormat:((isString)?@"'%@'":@"%@"), value];
		}
		
		if(key != [nonNilKeys lastObject]) {
			[keyStr appendString:@", "];
			[valueStr appendString:@", "];
		}
	}
	
	NSString* query = [NSString stringWithFormat:INSERT_OBJECT, [[object class] modelName], keyStr, valueStr];
	NSLog(@"create query:%@", query);
	
	BOOL okResult = YES;
	
	MYSQL* mConnection = [self mConnection];
	int resultsCode;
	if(0 != (resultsCode = mysql_query(mConnection, [query UTF8String]))) {
		NSLog(@"MySQL Error:%i - %s",  mysql_errno(mConnection), mysql_error(mConnection));
		okResult = NO;
	} else if(mysql_affected_rows(mConnection) < 1) {
		okResult = NO;
	}
	
	if(!hasUID) {
		//Set the insert value back to object as it was created by mysql and not locally.
		[object setValue:[NSNumber numberWithLong:(long)mysql_insert_id(mConnection)] 
				  forKey:[objectClass persistableKeyForDataSourceKey:identifierKey]];
	}
	
	return okResult;
}

- (BOOL)updateObject:(WebModelBase*)object {
	NSLog(@"sql: will update new record");
	
	Class objectClass = [object class];
	NSString* identifierKey = [objectClass identifierName];
	id identifierValue = [object valueForKey:identifierKey];
	
	if(!identifierKey) {
		NSLog(@"-- Cannot update an update that has not been saved yet...");
		return NO;
	}
	
	NSMutableString* setStr = [NSMutableString string];
	
	//If the uid is null, then we assume the database will create it, so we need to get it after the update
	
	NSArray* persistables = [[object class] allPersistableKeys];
	
	NSMutableArray* nonNilKeys = [NSMutableArray array];
	for(NSString* nkey in persistables) {
		if([object valueForKey:nkey]!=nil) {
			[nonNilKeys addObject:nkey];
		}
	}
	
	BOOL isString = YES;
	
	for(NSString* key in nonNilKeys) {
		[setStr appendFormat:@"`%@` = ", [objectClass dataSourceKeyForPersistableKey:key]];
		
		id nvalue = [object valueForKey:key];
		
		NSString* value = M_ValueForObject([object valueForKey:key], &isString);
		if([nvalue isKindOfClass:[NSData class]]) {
			[setStr appendFormat:@"'%@'", value];	//was X'%@'
		} else {
			[setStr appendFormat:((isString)?@"'%@'":@"%@"), value];
		}
		
		if(key != [nonNilKeys lastObject]) {
			[setStr appendString:@", "];
		}
	}
	
	BOOL cs = NO;
	NSString* clause = M_ValueForObject(identifierValue, &cs);
	
	NSString* whereClause = [NSString stringWithFormat:@"`%@` = %@",
							 [objectClass dataSourceKeyForPersistableKey:identifierKey],
							 [NSString stringWithFormat:cs?@"'%@'":@"%@", clause]];
	
	NSString* query = [NSString stringWithFormat:UPDATE_OBJECT, [[object class] modelName], setStr, whereClause];
	NSLog(@"create query:%@", query);
	
	BOOL okResult = YES;
	
	MYSQL* mConnection = [self mConnection];
	int resultsCode;
	if(0 != (resultsCode = mysql_query(mConnection, [query UTF8String]))) {
		NSLog(@"MySQL Error:%i - %s",  mysql_errno(mConnection), mysql_error(mConnection));
		okResult = NO;
	} else if(mysql_affected_rows(mConnection) < 1) {
		okResult = NO;
	}
	
	return okResult;
}

- (BOOL)deleteObject:(WebModelBase*)object {
	Class objectClass = [object class];
	
	BOOL asString;
	NSString* modelName	= [objectClass modelName];
	NSString* identifierKey = [objectClass identifierName];
	NSString* value = M_ValueForObject([object valueForKey:identifierKey], &asString);
	
	NSString* condition = [NSString stringWithFormat:(asString?@"`%@` = '%@'":@"`%@` = %@"), [objectClass dataSourceKeyForPersistableKey:identifierKey], value];
	NSString* query = [NSString stringWithFormat:DELETE_OBJECT, modelName, condition];
	
	MYSQL* mConnection = [self mConnection];
	int resultsCode;
	if(0 != (resultsCode = mysql_query(mConnection, [query UTF8String]))) {
		NSLog(@"MySQL Error:%i - %s",  mysql_errno(mConnection), mysql_error(mConnection));
		return NO;
	} else if(mysql_affected_rows(mConnection) < 1) {
		return NO;
	}
	return YES;
}

- (id)getObjectOfModel:(Class)aModelClass withIdentifier:(id)identifier  {
	NSString* query = [NSString stringWithFormat:SELECT_BY_ID, 
															[aModelClass modelName], 
															[aModelClass dataSourceKeyForPersistableKey:[aModelClass identifierName]], 
					   ([identifier isKindOfClass:[NSString class]])?[NSString stringWithFormat:@"'%@'", identifier]:[identifier stringValue]];
	NSLog(@"query:%@", query);
	
	NSArray* results = [self _getObjectsWithSQL:query ofClass:aModelClass];
	if([results count] > 0) 
		return [results objectAtIndex:0];
	else
		return nil;
}

- (NSString*)_recursiveQueryFromConditions:(NSDictionary*)conditions compoundType:(NSString*)type {
	NSMutableString* query = [NSMutableString string];
	NSString* compounder = nil;
	
	if(!type) 
		compounder = @"AND";
	else
		compounder = [type uppercaseString];
	
	//1. Build a query from the conditions dictionary
	NSArray* keys = [conditions allKeys];
	for(NSString* key in keys) {
		//Handle nested conditions
		if([key isEqualToString:@"OR"] || [key isEqualToString:@"AND"]) {
			NSString* subcompound = [self _recursiveQueryFromConditions:[conditions objectForKey:key] compoundType:key];
			[query appendFormat:@" (%@)", subcompound];
		} else {
			
			//Normal processing
			[query appendFormat:@" `%@`", key];
			
			id value = [conditions valueForKey:key];
			if([value isKindOfClass:[NSString class]]) {
				[query appendFormat:@" = '%@'", value];
			} else if([value isKindOfClass:[NSDictionary class]]) {
				NSString* condition = [(NSDictionary*)value valueForKey:@"condition"];
				if([condition isEqualToString:@"like"]) {
					[query appendFormat:@" like '%@'", [(NSDictionary*)value valueForKey:@"value"]];
				} else if([condition isEqualToString:@"contains"]) {
					[query appendFormat:@" like '%%%@%%'", [(NSDictionary*)value valueForKey:@"value"]];
				} else if([condition isEqualToString:@"startsWith"]) {
					[query appendFormat:@" like '%@%%'", [(NSDictionary*)value valueForKey:@"value"]];
				} else if([condition isEqualToString:@"endsWith"]) {
					[query appendFormat:@" like '%%%@'", [(NSDictionary*)value valueForKey:@"value"]];
				} else if([condition isEqualToString:@"between"]) {
					[query appendFormat:@" between ('%@', '%@')", [(NSDictionary*)value valueForKey:@"value"], [(NSDictionary*)value valueForKey:@"value2"]];
				} 
			} else if(value = [NSNull null]) {
				[query appendFormat:@" IS NULL"];
			}
		}
		
		if(key != [keys lastObject]) [query appendFormat:@" %@", compounder];
	}
	return query;
}

- (id)get:(ResultType)firstOrAll forObjectModel:(Class)aModelClass withConditions:(NSDictionary*)conditions {
	
	NSString* query = nil;
	if(firstOrAll == ResultFirst) {
		if(conditions)
			query = [NSString stringWithFormat:@"SELECT * FROM `%@` WHERE (%@) LIMIT 1", [aModelClass modelName], [self _recursiveQueryFromConditions:conditions compoundType:nil]];
		else
			query = [NSString stringWithFormat:@"SELECT * FROM `%@` LIMIT 1", [aModelClass modelName]];
	} else if(firstOrAll == ResultAll) {
		if(conditions)
			query = [NSString stringWithFormat:@"SELECT * FROM `%@` WHERE (%@)", [aModelClass modelName], [self _recursiveQueryFromConditions:conditions compoundType:nil]];
		else
			query = [NSString stringWithFormat:@"SELECT * FROM `%@`", [aModelClass modelName]];
	}
	
	//NSLog(@"query:%@", query);
	
	NSArray* results = [self _getObjectsWithSQL:query ofClass:aModelClass];
	//NSLog(@"results:%i", [results count]);
	
	if(firstOrAll == ResultFirst) {
		if([results count] == 1) {
			return [results objectAtIndex:0];
		} else {
			return nil;
		}
	}
	return results;
}

- (NSArray*)getObjectsOfModel:(Class)aModelClass withDataSourceQuery:(NSString*)dataSourceSpecificData {
	return [self _getObjectsWithSQL:dataSourceSpecificData ofClass:aModelClass];
}

- (void)beginTransaction:(NSString*)modelName {
}

- (id)endTransaction:(NSString*)modelName {
	return nil;
}


@end

@implementation WebMySQLConnection
@synthesize sql;
@synthesize lock;
@end

