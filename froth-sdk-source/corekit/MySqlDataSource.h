//
//  MySqlDataSource.h
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
#import "Froth.h"

#ifdef __APPLE__
#import <mysql.h>
#else
#import <mysql/mysql.h>
#endif

#include <pthread.h>
#define kSystemThreads 4
#define USE_THREAD_MODE 1

@interface WebMySQLConnection : NSObject {
	MYSQL* sql;
	pthread_mutex_t lock;
}
@property (nonatomic, assign) MYSQL* sql;
@property (nonatomic, assign) pthread_mutex_t lock;
@end

typedef struct {
	MYSQL* sql;
	pthread_mutex_t lock;
} sql_conn;

/*!
	\brief	Provides a mysql datasource for webApps
	\detail	Options requred in DataSources.
				-host
				-user
				-password
				-port
				-database
 
 
	ChangeLog
	- Thur 2:54:14 Aug 27/09
	Added a thread pool system to MySqlDataSource. Currently this
	is configurable with "PoolSize" datasource key
 */
@interface MySqlDataSource : NSObject <WebDataSource> {
#if USE_THREAD_MODE
#else
	MYSQL					*mConnection;
#endif
	
	NSDictionary*			m_connectionOptions;
	//NSMutableDictionary*	mConnectionPool;
	sql_conn				mpool[kSystemThreads];
	
	NSTimeZone				*serverTimeZone;
	unsigned int			mConnectionFlags;
	NSDateFormatter			*utcDateFormattter;
	NSStringEncoding		mEncoding;
}

@end
