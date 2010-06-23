//
//  WebModelBase.m
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

#import "WebModelBase.h"
#import "WebRequest.h"

#import "WebDataSourceController.h"
#import "WebDataSource.h"
#import "NSString+Utilities.h"
#import "JSON.h"

#import "Froth+Defines.h"
#import "Froth+Exceptions.h"

#ifdef TARGET_OS_COCOTRON
#import <objc/objc-class.h>
#else
#import <objc/objc.h>
#endif



@implementation WebModelBase
@synthesize uid;

#pragma mark -
#pragma mark Internal Functions

/*! 
	This function is dynamically added as a method at runtime
 */
static id findAllByMethodImp(id self, SEL _cmd, id value1) {
	NSString *methodBeingCalled = [NSString stringWithUTF8String:sel_getName(_cmd)];
	
	NSMutableDictionary* conditions = [NSMutableDictionary dictionary];

	NSArray* sections = [methodBeingCalled componentsSeparatedByString:@":"];
	for(NSString* section in sections) {
		NSString* fieldName = nil;
		if(section==[sections objectAtIndex:0]) {
			fieldName = [section stringByReplacingOccurrencesOfString:@"findAllBy_" withString:@""];
			[conditions setObject:value1 forKey:fieldName];
		}/* else if([section hasPrefix:@"and_"]) {
			[conditions setObject:value1 forKey:field];
		} else if([section hasPrefix:@"or_"]) {
			
		}*/
	}
	
	return [self findAllWithConditions:conditions];
}

static id findFirstByMethodImp(id self, SEL _cmd, id value1) {
	NSString *methodBeingCalled = [NSString stringWithUTF8String:sel_getName(_cmd)];
	
	NSMutableDictionary* conditions = [NSMutableDictionary dictionary];
	
	NSArray* sections = [methodBeingCalled componentsSeparatedByString:@":"];
	for(NSString* section in sections) {
		NSString* fieldName = nil;
		if(section==[sections objectAtIndex:0]) {
			fieldName = [section stringByReplacingOccurrencesOfString:@"findAllBy_" withString:@""];
			[conditions setObject:value1 forKey:fieldName];
		}/* else if([section hasPrefix:@"and_"]) {
		 [conditions setObject:value1 forKey:field];
		 } else if([section hasPrefix:@"or_"]) {
		 
		 }*/
	}
	
	return [self findFirstWithConditions:conditions];
}

#pragma mark -
#pragma mark Internal

- (void)m_setNotPersisted:(BOOL)aFlag {
	m_notPersisted = aFlag;
}

+ (NSString*)dataSourceName {
	return @"Default";
}

+ (NSString*)modelName {
	NSString* mName = NSStringFromClass(self);
	mName = [[mName stringByReplacingOccurrencesOfString:@"Model" withString:@""] retain];
	return [[mName lowercaseString] stringByAppendingString:@"s"];
}

+ (NSString*)identifierName {
	return @"uid";
}

+ (Class)identifierClass {
	return [NSString class];
}

+ (BOOL)hasStaticKeys {
	return YES;
}

+ (NSArray*)allPersistableKeys {
	//For subclasses.
	return nil;
}

+ (NSString*)dataSourceKeyForPersistableKey:(NSString*)key {
	return key;
}

+ (NSString*)persistableKeyForDataSourceKey:(NSString*)key {
	return key;
}

+ (id <WebDataSource>)dataSource {
	return [[WebDataSourceController controller] dataSourceForModel:self];
}

+ (void)beginTransactions {
	[[self dataSource] beginTransaction:[self modelName]];
}

+ (void)endTransactions {
	[[self dataSource] endTransaction:[self modelName]];
}

#pragma mark -
#pragma mark Lookup and Class Factory Methods


+ (id)objectWithIdentifier:(NSString *)identifier {
	return [[self dataSource] getObjectOfModel:self withIdentifier:identifier];
}

+ (NSArray*)all {
	return [[self dataSource] get:ResultAll forObjectModel:self withConditions:nil]; //Autoreleased
}

+ (NSArray*)findAllWithConditions:(NSDictionary *)conditions {
	return [[self dataSource] get:ResultAll forObjectModel:self withConditions:conditions]; //data source should autorelease
}

+ (id)findFirstWithConditions:(NSDictionary *)conditions {
	return [[self dataSource] get:ResultFirst forObjectModel:self withConditions:conditions]; //data source should autorelease
}

+ (int)countWithConditions:(NSDictionary *)conditions {
	return [[[self dataSource] get:ResultCount forObjectModel:self withConditions:conditions] intValue]; //data source should autorelease
}

+ (NSArray*)findWithQuery:(NSString*)query {
	return [[self dataSource] getObjectsOfModel:self withDataSourceQuery:query]; //autoreleased by datasource
}

#pragma mark -
#pragma mark Setup and Teardown

- (id)init {
	if(self = [super init]) {
		Class myClass = [self class];
		if([[myClass identifierClass] isEqual:[NSString class]]) {
			[self setValue:[NSString guid] forKey:[myClass identifierName]];
		}
		m_notPersisted = YES;
		m_dirtyKeys = [[[NSMutableArray alloc] initWithCapacity:30] retain];
		m_data = [[[NSMutableDictionary alloc] init] retain];
	}
	return self;
}

- (id)initFromDatabase {
	if(self = [super init]) {
		m_notPersisted = NO;
		m_dirtyKeys = [[[NSMutableArray alloc] initWithCapacity:30] retain];
		m_data = [[[NSMutableDictionary alloc] init] retain];
	}
	return self;
}

- (void)dealloc {
	[uid release];
	
	[m_data release];
	[m_dirtyKeys release];
	[m_datasource_data release];
	[super dealloc];
}

#pragma mark -
#pragma mark Internal FindBy Support

/*
 -find<All | First>By_<key>:(id)keyValue;
 //-find<All | First>By_<key>:(id)keyValue <or | and>_<key>:(id)keyValue ...;
 //-find<All | First>By_<key>:(id)keyValue and_<key>:(id)keyValue and_<key>:(id)keyValue ...;
 //-countOf_<key>:(id)keyValue;
 */

+ (BOOL)resolveClassMethod:(SEL)theMethod {
	NSString *methodBeingCalled = [NSString stringWithUTF8String: sel_getName(theMethod)];
	
	//findAllByMethodImp(self, sel, value)
	//findFirstByMethodImp(...);
	
	if([methodBeingCalled hasPrefix:@"findAllBy"]) {
		
		SEL newMethodSelector = sel_registerName([methodBeingCalled UTF8String]);
		
#ifndef TARGET_OS_COCOTRON
		Class selfMetaClass = objc_getMetaClass([[self className] UTF8String]);
		return (class_addMethod(selfMetaClass, newMethodSelector, (IMP) findAllByMethodImp, "@@:@")) ? YES : [super resolveClassMethod:theMethod];
#else
		if(class_getClassMethod([self class], newMethodSelector) != NULL) {
			return [super resolveClassMethod:theMethod];
		} else {
			BOOL isNewMethod = YES;
			Class selfMetaClass = objc_getMetaClass([[self className] UTF8String]);
			
			
			struct objc_method *newMethod = calloc(sizeof(struct objc_method), 1);
			struct objc_method_list *methodList = calloc(sizeof(struct objc_method_list)+sizeof(struct objc_method), 1);  
			
			newMethod->method_name = newMethodSelector;
			newMethod->method_types = "@@:@";
			newMethod->method_imp = (IMP) findAllByMethodImp;
			
			methodList->method_next = NULL;
			methodList->method_count = 1;
			memcpy(methodList->method_list, newMethod, sizeof(struct objc_method));
			free(newMethod);
			class_addMethods(selfMetaClass, methodList);
			
			assert(isNewMethod);
			return YES;
		}
#endif
	} else if([methodBeingCalled hasPrefix:@"findFirstBy"]) {
		
		SEL newMethodSelector = sel_registerName([methodBeingCalled UTF8String]);
		
#ifndef TARGET_OS_COCOTRON
		Class selfMetaClass = objc_getMetaClass([[self className] UTF8String]);
		return (class_addMethod(selfMetaClass, newMethodSelector, (IMP) findFirstByMethodImp, "@@:@")) ? YES : [super resolveClassMethod:theMethod];
#else
		if(class_getClassMethod([self class], newMethodSelector) != NULL) {
			return [super resolveClassMethod:theMethod];
		} else {
			BOOL isNewMethod = YES;
			Class selfMetaClass = objc_getMetaClass([[self className] UTF8String]);
			
			
			struct objc_method *newMethod = calloc(sizeof(struct objc_method), 1);
			struct objc_method_list *methodList = calloc(sizeof(struct objc_method_list)+sizeof(struct objc_method), 1);  
			
			newMethod->method_name = newMethodSelector;
			newMethod->method_types = "@@:@";
			newMethod->method_imp = (IMP) findFirstByMethodImp;
			
			methodList->method_next = NULL;
			methodList->method_count = 1;
			memcpy(methodList->method_list, newMethod, sizeof(struct objc_method));
			free(newMethod);
			class_addMethods(selfMetaClass, methodList);
			
			assert(isNewMethod);
			return YES;
		}
#endif
	}
	return [super resolveClassMethod:theMethod];
}

#pragma mark -
#pragma mark Persistance

- (void)didSaveForCreate {
	//For subclasses
}

- (void)didSaveForDelete {
	//For subclasses
}

- (void)didSaveForUpdate {
	//For subclasses
}

- (void)willSaveForDirty {
	//For subclasses
}

- (BOOL)save {
	BOOL success = NO;
	if([self isDirty]) {
		[self willSaveForDirty];
		
		Class myClass = [self class];
		if(m_notPersisted) {
			success = [[myClass dataSource] createObject:self];
			if(success)
				[self didSaveForCreate];
				
			
		} else {
			success = [[myClass dataSource] updateObject:self];
			if(success)
				[self didSaveForUpdate];
				
		}
		[m_dirtyKeys removeAllObjects];
	}
	return success;
}

- (BOOL)delete {
	Class myClass = [self class];
	if(!m_notPersisted) {
		if([[myClass dataSource] deleteObject:self]) {
			[self didSaveForDelete];
			return YES;
		}
	} 
	return NO;
}

#pragma mark -
#pragma mark Protocal Support

- (NSString*)description {
	/*NSMutableString* desc = [NSMutableString string];
	[desc appendFormat:@"<br><br>Name:%@ Identifier:%@<br>", [[self class] modelName], [self valueForKey:[[self class] identifierName]]];
	for(NSString* key in [[self class] allPersistableKeys]) {
		[desc appendFormat:@"{Key:%@ Value:%@}<br>", key, [self valueForKey:key]];
	}
	return desc;*/
	return froth_str(@"%@:[ data {%@} dirty {%@}]", NSStringFromClass([self class]), m_data, m_dirtyKeys);
}

#pragma mark -
#pragma mark Copying

- (id)copyWithZone:(NSZone*)zone {
	Class myClass = [self class];
	id aCopy = [[myClass alloc] init];
	NSArray* keys = [myClass allPersistableKeys];
	
	for(NSString* key in keys) {
		[aCopy setValue:[[self valueForKey:key] copy] forKey:key];
	}
	
	return aCopy;
}

#pragma mark -
#pragma mark Creation Methods From Post Data

+ (id)createWithProperties:(NSDictionary*)dictionary {
	id object = [[self alloc] init];
	for(NSString* key in [dictionary allKeys]) {
		[object setValue:[dictionary valueForKey:key] forKey:key];
	}
	return object;
}

+ (id)createWithXML:(NSXMLNode*)node {
	NSLog(@"*** WebModelBase: initWithXML: not implemented");
	return nil;
}

+ (id)createWithPostRequest:(WebRequest*)request {
	id data = [request postBody];
	
	//TODO: Auto increment id, or generate guid for identifiers if not included with the postRequest.
	if([data isKindOfClass:[NSXMLNode class]]) {
		return [self createWithXML:(NSXMLNode*)data];
	} else if([data isKindOfClass:[NSDictionary class]]) {
		return [self createWithProperties:(NSDictionary*)data];
	}
	return nil;
}

#pragma mark -
#pragma mark Dynamic Keys Support For @properties...

- (NSDictionary*)data {
	return m_data;
}

- (BOOL)hasAttribute:(NSString*)key {
	if([[self class] hasStaticKeys])
		return [[[self class] allPersistableKeys] containsObject:key];
	else
		return YES;
}

/*- (void)setValue:(id)value forKey:(NSString*)key {
	[self setValue:value forUndefinedKey:key];
}

- (id)valueForKey:(NSString*)key {
	return [self valueForUndefinedKey:key];
}*/

- (id)valueForUndefinedKey:(NSString*)key {
	if([self hasAttribute:key]) {
		return [m_data valueForKey:key];
	}
	return [super valueForUndefinedKey:key];
}

- (void)setValue:(id)value forUndefinedKey:(NSString*)key {
	if([self hasAttribute:key]) {
		SEL validatorSel = NSSelectorFromString(froth_str(@"validate%@:msg:", [key firstLetterCaptialized]));
		
		if([self respondsToSelector:validatorSel]) {
			NSString* errorMsg = nil;
			BOOL success;
			
			NSMethodSignature* signature = [super methodSignatureForSelector:validatorSel];
			NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
			[invocation setTarget:self];
			[invocation setSelector:validatorSel];
			
			//Setup pointer exchange
			id* valPtr = &value;
			NSString** msgPtr = &errorMsg;
			
			[invocation setArgument:&valPtr atIndex:2];
			[invocation setArgument:&msgPtr atIndex:3];
			[invocation invoke];
			[invocation getReturnValue:&success];
			
			if(!success) {
				froth_exception(@"ValidationException", errorMsg);
			}
		}
		
		id oldVal = [self valueForUndefinedKey:key];
		if(![value isEqual:oldVal]) {		
		
			[self dirty:key];
			if(value)
				[m_data setValue:value forKey:key];
			else
				[m_data removeObjectForKey:key];
		}
	} else {
		[super setValue:value forUndefinedKey:key];
	}
}

/* 
	Data source friendly for optomization, doesnt do validations just populates data
*/
- (void)setDataSourceValue:(id)value forKey:(NSString*)key {
	if([self hasAttribute:key]) {
		if(value)
			[m_data setValue:value forKey:key];
		else
			[m_data removeObjectForKey:key];
	} else {
		[super setValue:value forUndefinedKey:key];
	}
}

- (NSString*)attributeNameForSelector:(SEL)aSelector isSupported:(BOOL*)outIsSupported type:(NSString**)outType {
	
	//TODO: Implement a better way of insuring that a property is implemented, This would
	//be typically with objc_get_properties() or appropriate runtime function
	*outIsSupported = YES;
	
	NSString *selector = NSStringFromSelector(aSelector);   
    NSScanner *scanner = [NSScanner scannerWithString:selector];
    NSString *type;
    if([scanner scanUpToCharactersFromSet:[NSCharacterSet uppercaseLetterCharacterSet] intoString:&type]) {
        if([type isEqualToString:@"set"])
            *outType = @"setter";
        else
        {
			*outType = @"getter";
            [scanner setScanLocation:0];
        }
		
		// Make the first char lowercase
		NSString *attribute = [selector substringFromIndex:[scanner scanLocation]];
		NSString *firstChar = [attribute substringToIndex:1];
		
		attribute = [attribute stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:[firstChar lowercaseString]];
		attribute = [attribute stringByReplacingOccurrencesOfString:@":" withString:@""];
		return attribute;
    }
    else {
        *outType = @"getter";
		return selector;
    }
}

- (void)forwardInvocation:(NSInvocation *)invocation {
	BOOL isSupported;
	NSString* type;
	NSString* attribute = [self attributeNameForSelector:[invocation selector] isSupported:&isSupported type:&type];
	if(isSupported) {
		if([type isEqualToString:@"getter"]) {
			[invocation setSelector:@selector(valueForKey:)];
			[invocation setTarget:self];
			[invocation setArgument:&attribute atIndex:2];
			[invocation invoke];
		} else if ([type isEqualToString:@"setter"]) {
			[invocation setSelector:@selector(setValue:forKey:)];
			[invocation setTarget:self];
			[invocation setArgument:&attribute atIndex:3]; //index 2 is alread the value, 0, 1 are self, _cmd (ie target/selector)
			[invocation invoke];
		}
	} else {
		[super forwardInvocation:invocation];
	}
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
	BOOL isSupported;
	NSString* type;
	[self attributeNameForSelector:aSelector isSupported:&isSupported type:&type];
	
	NSMethodSignature *signature = nil;
	if(isSupported)
	{
		if([type isEqualToString:@"setter"])
			signature = [super methodSignatureForSelector:@selector(setValue:forKey:)];
		else if([type isEqualToString:@"getter"])
			signature = [super methodSignatureForSelector:@selector(valueForKey:)];
	} else {
		NSLog(@"type is not suppoerted for %@", NSStringFromSelector(aSelector));
	}
	
	if(signature != nil)
		return signature;
	else
		return [super methodSignatureForSelector:aSelector];
}

#pragma mark Dirty

- (NSArray*)dirtyKeys {
	return m_dirtyKeys;
}

- (BOOL)isDirty {
	return (m_dirtyKeys && m_dirtyKeys.count>0);
}

- (void)dirty:(NSString*)key {
	if(![m_dirtyKeys containsObject:key]) {
		[m_dirtyKeys addObject:key];
	}
}

- (void)clean:(NSString*)key {
	[m_dirtyKeys removeObject:key];
}

- (void)makeClean {
	[m_dirtyKeys removeAllObjects];
}

#pragma mark -
#pragma mark As NSObject

- (BOOL)isEqual:(id)otherObject {
	if([otherObject isKindOfClass:[WebModelBaseProxy class]]) {
		return [self.uid isEqualToString:[(WebModelBaseProxy*)otherObject uid]];
	}
	return [super isEqual:otherObject];
}

#pragma mark -
#pragma mark DataSource Customization Ability

- (NSMutableDictionary*)dataSourceData {
	if(!m_datasource_data)
		m_datasource_data = [[[NSMutableDictionary alloc] initWithCapacity:10] retain];
	return m_datasource_data;
}

@end

@implementation WebModelBaseProxy
@synthesize uid;

- (id)initWithUID:(NSString*)auid {
	if(self = [super init]) {
		self.uid = auid;
	}
	return self;
}

+ (id)with:(NSString*)aGUID {
	return [[[self alloc] initWithUID:aGUID] autorelease];
}

@end

@implementation WebModelBase (JSON)

#pragma mark -
#pragma mark JSON and Serailization

- (NSDictionary*)dictionaryRepresentation {
	NSArray* keys = [[self class] allPersistableKeys];
	
	if(!keys.count) {
		if(self.uid) {
			NSMutableDictionary* dictionary = [NSMutableDictionary dictionaryWithDictionary:[self data]];
			[dictionary setObject:self.uid forKey:@"uid"];
			return dictionary;
		}
		return [self data];
	}
	
	NSMutableDictionary* propertiesDictionary = [NSMutableDictionary dictionaryWithCapacity:[keys count]];
	for(NSString* key in keys) {
		id value = [self valueForKey:key];
		if(value)
			[propertiesDictionary setObject:value forKey:key];
	}
	NSString* identName = [[self class] identifierName];
	[propertiesDictionary setObject:[self valueForKey:identName] forKey:identName];
	return propertiesDictionary;
}

//Depreciated, this is replaced by -jsonProxyObject and NSObject+JSON's -JSONRepresentation
- (NSString*)JSONRepresentation {
	return [[self dictionaryRepresentation] JSONRepresentation];
}

//Allows for JSONRepresentation to properly work of a object, this dipreciates this class's JSONRepresentation implementation
- (id)proxyForJson {
	return [self dictionaryRepresentation];
}

@end

