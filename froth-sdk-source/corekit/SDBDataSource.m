//
//  SDBDataSource.m
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

#import "SDBDataSource.h"
#import "Froth+Defines.h"
#import "Froth+Exceptions.h"
#import "NSString+Utilities.h"

static NSDateFormatter* sdbDateFormatter = nil;

#define kMultiValueAddedKey		@"MultiValueAdded"
#define kMultiValueRemovedKey	@"MultiValueRemoved"

@implementation SDBDataSource

//_memcachedEnabled
- (id <WebDataSource>)initWithOptions:(NSDictionary*)theOptions {
	if(self = [super init]) {
		_memcachedEnabled = [[theOptions valueForKey:@"UseMemcached"] boolValue];
		_awsAccount = [[theOptions valueForKey:@"account"] retain];
		_awsSecret = [[theOptions valueForKey:@"secret"] retain];
	}
	return self;
}

- (void)dealloc {
	[_awsAccount release], _awsAccount = nil;
	[_awsSecret release], _awsSecret = nil;
	[sdbDateFormatter release], sdbDateFormatter = nil;
	[super dealloc];
}

- (NSDateFormatter*)dateFormatter {
	if(!sdbDateFormatter) {
		sdbDateFormatter = [[[NSDateFormatter alloc] init] retain];
#ifdef __APPLE__
		[sdbDateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"]; //1997-03-12T23:34:43+0700
#else
		[sdbDateFormatter setDateFormat:@"%Y-%m-%dT%H:%M:%S%z"];
#endif
	}
	return sdbDateFormatter;
}

- (NSString*)_encodedStringForValue:(id)value type:(int)type {
	if(type == 0) {			//STRING
		return value;
	} else if(type == 1) {	//FLOAT
		//TODO do the lex compuations on it for lex support
		return [value stringValue];
	} else if(type == 2) {	//BOOL
		return [value stringValue];
	} else if(type == 3) {	//INT
		return [value stringValue];
	} else if(type == 7) {	//TIMESTAMP
		if(![value isEqual:[NSNull null]]) {
			NSString* dateStr = [NSString stringWithFormat:@"%f", [(NSDate*)value timeIntervalSince1970]];//[[self dateFormatter] stringFromDate:(NSDate*)value];
			return dateStr;
		} else { 
			return @"null";
		}
	}
	return [value description];
}

- (id)_decodedObjectForValue:(NSString*)value type:(int)type {
	if(type == 0) {			//STRING
		return value;
	} else if(type == 1) {	//FLOAT
		//TODO do the lex compuations on it for lex support
		return [NSNumber numberWithFloat:[value floatValue]];
	} else if(type == 2) {	//BOOL
		return [NSNumber numberWithBool:[value boolValue]];
	} else if(type == 3) {	//INT
		return [NSNumber numberWithInt:[value intValue]];
	} else if(type == 7) {	//TIMESTAMP
		if([value length] > 4) {
			return [NSDate dateWithTimeIntervalSince1970:[value doubleValue]];//[[self dateFormatter] dateFromString:value];
		} else {
			return nil;
		}
	} else if(type == 5) {	//ARRAY
		/*
		  This is only needed when the WebModelBase subclass wants an array, but only one object
		  is returned by the key (if more, its already an array)
		 */
		return [NSArray arrayWithObject:value];
	}
	return [value description];
}

- (BOOL)createObject:(WebModelBase*)object {
	Class aClass = [object class];
	NSString* name = [object valueForKey:[aClass identifierName]];
	if(!name)
		froth_exception(@"SDBDataSourceObjectsMustHaveIdentifier", @"Amazon simple db requires a name for items. this name is the object's identifier key and it is nil for createObject:");

	SDBDataConnector* sdb = [SDBDataConnector sharedDataConnectorForAccount:_awsAccount secret:_awsSecret];
	
	NSArray* dirtyKeys = [object dirtyKeys];
	NSMutableArray* sdbKeys = [NSMutableArray arrayWithCapacity:[dirtyKeys count]];
	NSMutableArray* sdbVals = [NSMutableArray arrayWithCapacity:[dirtyKeys count]];
	
	for(NSString* localKey in dirtyKeys) {
		id nextVal = [object valueForKey:localKey];
		NSString* dsKey = [aClass dataSourceKeyForPersistableKey:localKey];
		if(nextVal) {			
			if(![nextVal isKindOfClass:[NSArray class]]) {
				[sdbKeys addObject:dsKey];
				SEL typeSel = NSSelectorFromString(froth_str(@"dataTypeFor%@", [localKey firstLetterCaptialized]));
				if([aClass respondsToSelector:typeSel]) {
					int type = [[aClass performSelector:typeSel] intValue];
					//[sdbVals addObject:[self _encodedStringForValue:nextVal type:type]];
					[sdbVals addObject:(nextVal==[NSNull null])?@"((null))":[self _encodedStringForValue:nextVal type:type]];
				} else {
					//Just make it a string.
					//[sdbVals addObject:[self _encodedStringForValue:nextVal type:0]];
					[sdbVals addObject:(nextVal==[NSNull null])?@"((null))":[self _encodedStringForValue:nextVal type:0]];
				}
			} else {
				NSArray* multi = (NSArray*)nextVal;
				for(id value in multi) {
					[sdbKeys addObject:dsKey];
					[sdbVals addObject:value];
				}
			}
		} 
	}
	if([sdbKeys count]) {
		//TODO: dynamically compute the domain using the last to digits of a hash of the name. for ditrubuted domains
		
		/*
			For distrubuted objects, use extended class method +(BOOL)dataSourcePartitionDomain
		 */		
		[sdb setValues:sdbVals forKeys:sdbKeys forItem:name inDomain:[aClass modelName]];
	}
	return YES;
}

- (BOOL)updateObject:(WebModelBase*)object {
	
	/*!
		Note! Even though this is an update, currently for speed it makes no assumsion if the object already exists. If its does it
				simply fails.
	 */
	
	Class aClass = [object class];
	
	NSString* domain = [aClass modelName];
	NSString* name = [object valueForKey:[aClass identifierName]];
	if(!name)
		froth_exception(@"SDBDataSourceObjectsMustHaveIdentifier", @"Amazon simple db requires a name for items. this name is the object's identifier key and it is nil for createObject:");
	
	SDBDataConnector* sdb = [SDBDataConnector sharedDataConnectorForAccount:_awsAccount secret:_awsSecret];
	
	//This operation may do multiple writes, for this we sdbdataconnectors multiOperations support
	BOOL shouldCommit = NO;
	if(![sdb inMultiMode]) {
		[sdb beginMultiOperations];
		shouldCommit = YES;
	}
	
	NSArray* dirtyKeys = [object dirtyKeys];
	NSMutableArray* sdbKeys = [NSMutableArray arrayWithCapacity:[dirtyKeys count]];
	NSMutableArray* sdbVals = [NSMutableArray arrayWithCapacity:[dirtyKeys count]];
	//NSMutableArray* sdbDeletes = [NSMutableArray arrayWithCapacity:[dirtyKeys count]];	//provides for setting a value to [NSNull null] to deleted it
	
	for(NSString* localKey in dirtyKeys) {
		id nextVal = [object valueForKey:localKey];
		NSString* dsKey = [aClass dataSourceKeyForPersistableKey:localKey];
		if(nextVal) {			
			if(![nextVal isKindOfClass:[NSArray class]]) {
				//if(nextVal == [NSNull null]) {
				//	sdbDeletes
				//} else {
					[sdbKeys addObject:dsKey];
					
					SEL typeSel = NSSelectorFromString(froth_str(@"dataTypeFor%@", [localKey firstLetterCaptialized]));
					if([aClass respondsToSelector:typeSel]) {
						int type = [[aClass performSelector:typeSel] intValue];
						[sdbVals addObject:(nextVal==[NSNull null])?@"((null))":[self _encodedStringForValue:nextVal type:type]];
					} else {
						//Just make it a string.
						[sdbVals addObject:(nextVal==[NSNull null])?@"((null))":[self _encodedStringForValue:nextVal type:0]];
					}
				//}
			} else {
				NSArray* addedMulti = [[[object dataSourceData] valueForKey:kMultiValueAddedKey] valueForKey:localKey];
				NSArray* removedMulti = [[[object dataSourceData] valueForKey:kMultiValueRemovedKey] valueForKey:localKey];
				
				NSMutableArray* valuesToRemove = [NSMutableArray array];
				NSMutableArray* keysToRemove = [NSMutableArray array];
				for(id remVal in removedMulti) {
					[valuesToRemove addObject:remVal];
					[keysToRemove addObject:dsKey];
				} 
				if(valuesToRemove.count)
					[sdb deleteValues:valuesToRemove forKeys:keysToRemove forItem:name inDomain:domain];
				
				//Add added to main operation
				NSMutableArray* multiValsToAdd = [NSMutableArray array];
				NSMutableArray* multiKeysToAdd = [NSMutableArray array];
				for(id addVal in addedMulti) {
					[multiValsToAdd addObject:addVal];
					[multiKeysToAdd addObject:dsKey];
				}
				if(multiKeysToAdd.count)
					[sdb setValues:multiValsToAdd forKeys:multiKeysToAdd forItem:name inDomain:domain];
			}
		} 
	}
	if([sdbKeys count]) {
		//TODO: dynamically compute the domain using the last to digits of a hash of the name. for ditrubuted domains
		
		/*
		 For distrubuted objects, use extended class method +(BOOL)dataSourcePartitionDomain
		 */
		
		//We do a replace so we know it properly was written
		[sdb replaceValues:sdbVals forKeys:sdbKeys forItem:name inDomain:domain];
	}
	
	if(shouldCommit) 
		[sdb endMultiOperations];
	
	return YES;
}

- (BOOL)deleteObject:(WebModelBase*)object {
	/*
	 For distrubuted objects, use extended class method +(BOOL)dataSourcePartitionDomain
	 */
	[[SDBDataConnector sharedDataConnectorForAccount:_awsAccount secret:_awsSecret] deleteItem:object.uid inDomain:[[object class] modelName]];
	return YES;
}

//Auto releases object initialized here
- (WebModelBase*)_objectFromData:(NSDictionary*)attributes identifier:(NSString*)identifier model:(Class)model {
	
	if(!attributes ||![attributes.allKeys count] || !identifier || !model)
		return nil;
	
	WebModelBase* object = [[model alloc] initFromDatabase];
	object.uid = identifier;
	
	if(attributes) {
		NSArray* keys = [attributes allKeys];
		for(NSString* key in keys) {
			id value = [attributes valueForKey:key];
			if([value isKindOfClass:[NSArray class]]) {
				[object setDataSourceValue:value forKey:[model persistableKeyForDataSourceKey:key]];
			} else {
				NSString* localKey = [model persistableKeyForDataSourceKey:key];
				SEL typeSel = NSSelectorFromString(froth_str(@"dataTypeFor%@", [localKey firstLetterCaptialized]));
				if([model respondsToSelector:typeSel]) {
					[object setDataSourceValue:([value isEqualToString:@"((null))"])?[NSNull null]:[self _decodedObjectForValue:value type:[[model performSelector:typeSel] intValue]] forKey:localKey];
				} else {
					[object setDataSourceValue:([value isEqualToString:@"((null))"])?[NSNull null]:value forKey:localKey];
				}
			}
		}
	}
	[object makeClean];
	return [object autorelease];
}

- (id)getObjectOfModel:(Class)aModelClass withIdentifier:(id)identifier {
	/*
	 For distrubuted objects, use extended class method +(BOOL)dataSourcePartitionDomain
	 We need to get/check from all availible partitioned domains
	 */
	
	
	//NSTimeInterval start = [[NSDate date] timeIntervalSinceReferenceDate];
	NSDictionary* attributes = [[SDBDataConnector sharedDataConnectorForAccount:_awsAccount secret:_awsSecret] getAttributesForItem:identifier inDomain:[aModelClass modelName]];
	//NSLog(@"[TIME]:time for getByIdentifier() [%f]", [[NSDate date] timeIntervalSinceReferenceDate] - start);
	return [self _objectFromData:attributes identifier:identifier model:aModelClass];
}

- (NSString*)_recursiveQueryFromConditions:(NSDictionary*)conditions compoundType:(NSString*)type {
	NSMutableString* query = [NSMutableString string];
	NSString* compounder = nil;
	
	if(!type) 
		compounder = @"and";
	else
		compounder = [type lowercaseString];
	
	//1. Build a query from the conditions dictionary
	NSArray* keys = [conditions allKeys];
	for(NSString* key in keys) {
		//Handle nested conditions
		if([[key lowercaseString] isEqualToString:@"or"] || [[key lowercaseString] isEqualToString:@"and"]) {
			NSString* subcompound = [self _recursiveQueryFromConditions:[conditions objectForKey:key] compoundType:key];
			[query appendFormat:@" (%@)", subcompound];
		} else {
			
			//Normal processing
			if([key hasPrefix:@"every("])
				[query appendFormat:@" %@", key];
			else
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
					[query appendFormat:@" between '%@' and '%@'", [(NSDictionary*)value valueForKey:@"value"], [(NSDictionary*)value valueForKey:@"value2"]];
				} 
			} else if(value = [NSNull null]) {
				[query appendFormat:@" is null"];
			}
		}
		
		if(key != [keys lastObject]) [query appendFormat:@" %@", compounder];
	}
	return query;
}

- (id)get:(ResultType)firstOrAll forObjectModel:(Class)aModelClass withConditions:(NSDictionary*)conditions {
	
	/*
		TODO: handle aggragate requests (using multi statements) accross all partitioned domains if supported
	 */
	NSString* domain = [aModelClass modelName];
	NSString* query = nil;
	if(firstOrAll == ResultFirst) {
		if(conditions)
			query = [NSString stringWithFormat:@"select * from `%@` where (%@) limit 1", domain, [self _recursiveQueryFromConditions:conditions compoundType:nil]];
		else
			query = [NSString stringWithFormat:@"select * from `%@` limit 1", domain];
	} else if(firstOrAll == ResultAll) {
		if(conditions)
			query = [NSString stringWithFormat:@"select * from `%@` where (%@)", domain, [self _recursiveQueryFromConditions:conditions compoundType:nil]];
		else
			query = [NSString stringWithFormat:@"select * from `%@`", domain];
	} else if(firstOrAll == ResultCount) {
		if(conditions)
			query = [NSString stringWithFormat:@"select count(*) from `%@` where (%@)", domain, [self _recursiveQueryFromConditions:conditions compoundType:nil]];
		else
			query = [NSString stringWithFormat:@"select count(*) from `%@`", domain];
	}
	
	//NSLog(@"simpledb query: %@", query);
	NSArray* results = [[SDBDataConnector sharedDataConnectorForAccount:_awsAccount secret:_awsSecret] getItemsWithSelect:query];
	
	if(firstOrAll == ResultFirst) {
		if([results count]) {
			NSDictionary* dic = [results objectAtIndex:0];
			NSString* key = [dic.allKeys objectAtIndex:0];
			return [self _objectFromData:[dic objectForKey:key] identifier:key model:aModelClass];
		} else {
			return nil;
		}
	} else if(firstOrAll == ResultCount) {
		if(results.count>0)
			return [[results objectAtIndex:0] valueForKeyPath:@"Domain.Count"];
		else
			return @"0";
	}
	
	NSMutableArray* convRes = [NSMutableArray arrayWithCapacity:[results count]];
	for(NSDictionary* res in results) {
		NSString* key = [res.allKeys objectAtIndex:0];
		[convRes addObject:[self _objectFromData:[res objectForKey:key] identifier:key model:aModelClass]];
	}
	
	return convRes; //Auto released
}
	
- (NSArray*)getObjectsOfModel:(Class)aModelClass withDataSourceQuery:(NSString*)dataSourceSpecificData {
	NSArray* results = [[SDBDataConnector sharedDataConnectorForAccount:_awsAccount secret:_awsSecret] getItemsWithSelect:dataSourceSpecificData];
	NSMutableArray* convRes = [NSMutableArray arrayWithCapacity:[results count]];
			
	for(NSDictionary* res in results) {
		NSString* key = [res.allKeys objectAtIndex:0];
		[convRes addObject:[self _objectFromData:[res objectForKey:key] identifier:key model:aModelClass]]; //object safly retained by convRes array.
	}
	
	return convRes; //Auto released...
}

#pragma mark -
#pragma mark Aggragate Operations (Transaction)

/*
	We dont care about the model classes as the backing sdbdataconnector supports aggragate operaiont
	on multiple domains
 */

- (void)beginTransaction:(NSString*)modelName {
	_asTransaction = YES;
	[[SDBDataConnector sharedDataConnectorForAccount:_awsAccount secret:_awsSecret] beginMultiOperations];
}

- (id)endTransaction:(NSString*)modelName {
	_asTransaction = NO;
	[[SDBDataConnector sharedDataConnectorForAccount:_awsAccount secret:_awsSecret] endMultiOperations];
	return [[SDBDataConnector sharedDataConnectorForAccount:_awsAccount secret:_awsSecret] multiResults];
}

@end
				
@implementation WebModelBase (SDBDataSource) 

//Indicates a dirty multi value, by adding it to the dataSourceData mutuble userInfo
- (void)_markDirtyAddValue:(id)value forKey:(NSString*)key {
	NSMutableDictionary* addedMultDictionary = [[self dataSourceData] valueForKey:kMultiValueAddedKey];
	if(!addedMultDictionary) { 
		addedMultDictionary = [NSMutableDictionary dictionary];
		[[self dataSourceData] setValue:addedMultDictionary forKey:kMultiValueAddedKey];
	}
	
	NSMutableArray* multiChangeValueArray = [addedMultDictionary valueForKey:key];
	if(!multiChangeValueArray) {
		multiChangeValueArray = [NSMutableArray array];
		[addedMultDictionary setObject:multiChangeValueArray forKey:key];
	}
	[multiChangeValueArray addObject:value];
}

- (void)_markDirtyRemoveValue:(id)value forKey:(NSString*)key {
	NSMutableDictionary* addedMultDictionary = [[self dataSourceData] valueForKey:kMultiValueRemovedKey];
	if(!addedMultDictionary) { 
		addedMultDictionary = [NSMutableDictionary dictionary];
		[[self dataSourceData] setValue:addedMultDictionary forKey:kMultiValueRemovedKey];
	}
	
	NSMutableArray* multiChangeValueArray = [addedMultDictionary valueForKey:key];
	if(!multiChangeValueArray) {
		multiChangeValueArray = [NSMutableArray array];
		[addedMultDictionary setObject:multiChangeValueArray forKey:key];
	}
	[multiChangeValueArray addObject:value];
}

- (void)addValue:(id)value forKey:(NSString*)key {
	if(value && key) {
		NSArray* currentValues = [self valueForUndefinedKey:key];
		if(!currentValues) {
			NSMutableArray* mutibleVals = [NSMutableArray array];
			[mutibleVals addObject:value]; //?
			
			//Mark dirty
			[self _markDirtyAddValue:value forKey:key];
			
			//Add the change??
			[self setValue:mutibleVals forUndefinedKey:key];
		} else if(![currentValues isKindOfClass:[NSArray class]]) {
			NSMutableArray* mutibleVals = [NSMutableArray array];
			[mutibleVals addObject:currentValues];
			[mutibleVals addObject:value];
			[self _markDirtyAddValue:value forKey:key];
			[self _markDirtyAddValue:currentValues forKey:key];
			[self setValue:mutibleVals forUndefinedKey:key];
		} else {
			if(![currentValues containsObject:value]) {
				[self setValue:[currentValues arrayByAddingObject:value] forUndefinedKey:key];
				[self _markDirtyAddValue:value forKey:key];
			}
		}
	}
}

- (void)removeValue:(id)value forKey:(NSString*)key {
	if(value && key) {
		NSArray* currentValues = [self valueForUndefinedKey:key];		
		if(!currentValues) {
			NSMutableArray* mutibleVals = [NSMutableArray array];
			[mutibleVals addObject:value]; //?
			
			//Mark dirty
			[self _markDirtyRemoveValue:value forKey:key];
		} else if(![currentValues isKindOfClass:[NSArray class]]) {
			[self _markDirtyRemoveValue:value forKey:key];
			[self setValue:[NSArray array] forUndefinedKey:key];
		} else { 
			if([currentValues containsObject:value]) {

				NSMutableArray* newArr = [NSMutableArray arrayWithArray:currentValues];
				[newArr removeObject:value]; //value is now released...
				[self setValue:newArr forUndefinedKey:key];
			
				[self _markDirtyRemoveValue:value forKey:key];
			}
		}
	}
}

- (void)addValues:(NSArray*)values forKey:(NSString*)key {
	for(id object in values) {
		[self addValue:object forKey:key];
	}
}

@end