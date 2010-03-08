//
//  WebDataSourceController.m
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

#import "WebDataSourceController.h"
#import "WebModelBase.h"
#import "MemoryDataSource.h"

static WebDataSourceController* _staticController = nil;

//Should be made thread safe with locks and synchronization
static MemoryDataSource* _staticSharedMemorySource;

@implementation WebDataSourceController

+ (WebDataSourceController*)controller {
	@synchronized(_staticController) {
		if(!_staticController) {
			_staticController = [[WebDataSourceController alloc] init];
		}
	}
	//NSLog(@" [[WebDataSourceController instance:%@]]", _staticController);
	return _staticController;
}

- (id)init {
	if(self = [super init]) {		
		if(!m_initializedDataSources)
			m_initializedDataSources = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (void)dealloc {
	[m_initializedDataSources release];
	[super dealloc];
}

- (id <WebDataSource>)dataSourceForModel:(Class)model {
	NSString* sourceName = [model dataSourceName];
	
	id <WebDataSource> ds = nil;
	@synchronized(m_initializedDataSources) {
	ds = [m_initializedDataSources objectForKey:sourceName];

	if(!ds) {
		
		BOOL initializedDataSource = NO;
		
#ifndef __APPLE__
		NSBundle* bundle = [NSBundle mainBundle];
#else
		NSBundle* bundle = [NSBundle bundleForClass:model];
#endif
		NSString* configPath = [bundle pathForResource:@"DataSources" ofType:@"plist"];
		if(configPath) {
			NSDictionary* config = [[NSDictionary alloc] initWithContentsOfFile:configPath];
		
			NSDictionary* dataSourceInfo = [config valueForKey:sourceName];
			NSString* className = [dataSourceInfo valueForKey:@"class"];
			//NSLog(@"className:%@", className);
			if(className) {
				ds = [[NSClassFromString(className) alloc] initWithOptions:[dataSourceInfo objectForKey:@"options"]];
				
				//return ds;	//makes it per/request db connections
				if(ds) {
					[m_initializedDataSources setObject:ds forKey:sourceName];
					initializedDataSource = YES;
				}
			}
		}
		
		//Check for internal defualts that dont require DataSources files (these can be overideable) Ie use memory datasource
		if(!initializedDataSource) {
			//@synchronized(_staticSharedMemorySource) {
				MemoryDataSource* mds = [m_initializedDataSources objectForKey:@"MEMORY_DATASOURCE"];
				if(!mds) {
					NSLog(@"Creating the defualt memory data source for runtime memory objects");
					//Cache it and make it synchronized for thread safty as it should be shared accross all threads
					_staticSharedMemorySource = [[MemoryDataSource alloc] initWithOptions:nil];
					[m_initializedDataSources setObject:_staticSharedMemorySource forKey:@"MEMORY_DATASOURCE"];
					
						//For faster lookup we well also up the object under the session data source defualt if needed for model.
					if([sourceName isEqualToString:@"SessionStorage"])
						[m_initializedDataSources setObject:_staticSharedMemorySource forKey:@"SessionStorage"];
				
					return _staticSharedMemorySource;
				} else {
					return mds;
				}
			//}
		}
	}
	}
	return ds;
}

@end
