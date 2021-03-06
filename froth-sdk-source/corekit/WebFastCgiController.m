/****************************************************************************
 * Framework for Objective-C                                                *
 *                                                                          *
 * Copyright (c) 2008 Vladimir "Farcaller" Pouzanov <farcaller@gmail.com>   *
 *                                                                          *
 * Permission is hereby granted, free of charge, to any person obtaining a  *
 * copy of this software and associated documentation files                 *
 * (the "Software"), to deal in the Software without restriction, including *
 * without limitation the rights to use, copy, modify, merge, publish,      *
 * distribute, sublicense, and/or sell copies of the Software, and to       *
 * permit persons to whom the Software is furnished to do so, subject to    *
 * the following conditions:                                                *
 *                                                                          *
 * The above copyright notice and this permission notice shall be included  *
 * in all copies or substantial portions of the Software.                   *
 *                                                                          *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS  *
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF               *
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.   *
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY     *
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,     *
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE        *
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                   *
 ****************************************************************************/

#import "WebFastCgiController.h"
#import "WebRequest+FastCGI.h"
#import "WebResponse.h"

#import <stdlib.h>
#include <pthread.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/errno.h>
#include <unistd.h>

#import "Froth+Defines.h"

void* r_thread_accept(void* initDict) {
	NSAutoreleasePool *gpool = [[NSAutoreleasePool alloc] init];
	
	WebApplication* webApp = [(NSDictionary*)initDict valueForKey:@"application"];
	NSNumber* threadIndex = [(NSDictionary*)initDict valueForKey:@"threadIndex"];
	
	int rc;
	FCGX_Request request;
	FCGX_InitRequest(&request, 0, 0);
	
	for(;;) {
		static pthread_mutex_t accept_mutex = PTHREAD_MUTEX_INITIALIZER;
		static pthread_mutex_t counts_mutex = PTHREAD_MUTEX_INITIALIZER;
		
		/* Some platforms require accept() serialization, some don't.. */
		pthread_mutex_lock(&accept_mutex);
		rc = FCGX_Accept_r(&request);
		pthread_mutex_unlock(&accept_mutex);
		
		if(rc < 0) break; //No new connection to accept...
		
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		WebMutableRequest *rq = [[WebMutableRequest alloc] init];	
		
		@try {
			//Timer for stats
			NSDate *start = [NSDate dateWithTimeIntervalSinceNow:0];
			
			[rq setHTTPRequestPointer:request.envp];
			NSString* method = [rq method];
			
			NSData* reqBodyData = nil;
			int dataLen = [[rq.headers objectForKey:@"CONTENT_LENGTH"] intValue];
			
			if([method isEqualToString:@"POST"] || 
			   [method isEqualToString:@"PUT"] || 
			   [method isEqualToString:@"DELETE"]) {
				void *buf = malloc(dataLen+1);
				assert(buf);
				while (FCGX_GetStr(buf, dataLen, request.in) < dataLen) {
					///Do something meaningfull??...
				}
				
				//buf[dataLen] = '\0';
				reqBodyData = [[NSData alloc] initWithBytes:buf length:dataLen];
				free(buf);
				
				[rq setBodyDataValue:reqBodyData];
				[reqBodyData release];
			}
			
			WebResponse *rs;
			
			//TEMP: bypass for favicon.ico until we get this implemented...
			if(![rq.uri hasSuffix:@"favicon.ico"]) {
				rs = [webApp performSelector:@selector(handle:) withObject:rq];
			} else {
				rs = [WebResponse responseWithCode:404];
			}
			
			if(!rs) {
				[NSException raise:@"InvalidWebResponseObject" format:@"Probably becouse an action was defined, but returned a nil WebResponse instance", nil];
			} else {
				//Remove body from HEAD requests
				if([method isEqualToString:@"HEAD"]) {
					[rs setBody:nil];
				}
			}
			
			FCGX_SetExitStatus(rs.code, request.out);
			
			pthread_mutex_lock(&counts_mutex);
			FCGX_FPrintF(request.out, "%s", [[rs dump] bytes]);
			pthread_mutex_unlock(&counts_mutex);
			
			float t = -[start timeIntervalSinceNow];			
			NSLog(@"FOWResolver: request [%@][%@] completed in [%.4f] on thread [%@]", rq.method, rq.uri,  t, threadIndex);
		} @catch (NSException *exception) {
			FCGX_SetExitStatus(500, request.out);
			NSMutableString *err = [NSMutableString stringWithFormat:
									@"Content-type: text/html\n\n\
									<html><head><title>Froth Exception</title></head> \
									<body>Uncaught exception: <strong>%@</strong>: <pre>%@</pre>\nStack trace:<ul>\n", [exception name], [exception reason]];
			[err appendFormat:@"</ul><br>UserInfo:%@", [exception userInfo]];
			[err appendString:@"</body></html>"];
			
			NSLog(@"******** FOWFastCgiController: Recovery from exception [%@] [%@]", [exception name], [exception description]);
			
			pthread_mutex_lock(&counts_mutex);
			FCGX_FPrintF(request.out, "%s", [err UTF8String]);
			pthread_mutex_unlock(&counts_mutex);
		} @finally {
			[rq release];
		}
		
		FCGX_Finish_r(&request);
		
		[pool drain];
	}
	
	[gpool drain];	
	return NULL;
}

@implementation WebFastCgiController

@synthesize threadCount;

#pragma mark -
#pragma mark Cocoa Utilities

- (id)initWithWebApplication:(WebApplication*)app path:(NSString*)path chmod:(int)c {
	if(self = [super init]) {
		threadCount = [[app class] workerThreads];
		sock = FCGX_OpenSocket([path UTF8String], 1024); //path here is a port...
		if(!sock){
			@throw [NSException
					exceptionWithName:@"OpenSocketException"
					reason:[NSString stringWithFormat:@"FCGX_OpenSocket() failed for path %@: %s", path, strerror(errno)]
					userInfo:nil];
		}
		if(c>=0){
			if(chmod([path UTF8String], c) == -1){
				char *er = strerror(errno);
				@throw [NSException
						exceptionWithName:@"OpenSocketException"
						reason:[NSString stringWithFormat:@"fchmod(sock) failed for path %@: %s", path, er]
						userInfo:nil];
			}
		}
		if(FCGX_Init() != 0)
			exit(99);
		
		if(FCGX_IsCGI()){
			NSLog(@"*** FastCGI Mode as CGI ***");
		}
		
		webApp = [app retain];
	}
	return self;
}

- (void)dealloc {
	close(sock);
	
	[webApp release]; webApp = nil;
	[super dealloc];
}

- (void)processRequests {
	int i;
	for(i=0; i<threadCount-1; ++i) {
		[NSThread detachNewThreadSelector:@selector(threadTask:)
								 toTarget:self
							   withObject:[NSNumber numberWithInt:i]];
	}
	
	//The main thread needs to stay working as well.
	[self threadTask:[NSNumber numberWithInt:i]];
}

- (void)threadTask:(id)unused {
	[[[NSThread currentThread] threadDictionary] setValue:unused forKey:@"location"];
	
	NSAutoreleasePool *gpool = [[NSAutoreleasePool alloc] init];
	
	//self.threadCount = [unused intValue];
	
	int rc;
	FCGX_Request request;
	FCGX_InitRequest(&request, sock, 0);

	//NSLog(@"Starting thread task");
	for(;;) {
		static pthread_mutex_t accept_mutex = PTHREAD_MUTEX_INITIALIZER;
		static pthread_mutex_t counts_mutex = PTHREAD_MUTEX_INITIALIZER;
		
		/* Some platforms require accept() serialization, some don't.. */
		pthread_mutex_lock(&accept_mutex);
		rc = FCGX_Accept_r(&request);
		pthread_mutex_unlock(&accept_mutex);
		
		if(rc < 0) break; //No new connection to accept...
		
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		WebMutableRequest *rq = [[WebMutableRequest alloc] init];	
		
		@try {
			//Timer for stats
			NSDate *start = [NSDate dateWithTimeIntervalSinceNow:0];
			
			[rq setHTTPRequestPointer:request.envp];
			NSString* method = [rq method];
			
			NSData* reqBodyData = nil;
			int dataLen = [[rq.headers objectForKey:@"CONTENT_LENGTH"] intValue];
			
			if([method isEqualToString:@"POST"] || 
			   [method isEqualToString:@"PUT"] || 
			   [method isEqualToString:@"DELETE"]) {
				void *buf = malloc(dataLen+1);
				assert(buf);
				while (FCGX_GetStr(buf, dataLen, request.in) < dataLen) {
					///Do something meaningfull??...
				}
				
				//buf[dataLen] = '\0';
				reqBodyData = [[NSData alloc] initWithBytes:buf length:dataLen];
				free(buf);
				
				[rq setBodyDataValue:reqBodyData];
				[reqBodyData release];
			}
			
			WebResponse *rs;
			
			//TEMP: bypass for favicon.ico until we get this implemented...
			if(![rq.uri hasSuffix:@"favicon.ico"]) {
				rs = [webApp performSelector:@selector(handle:) withObject:rq];
			} else {
				rs = [WebResponse responseWithCode:404];
			}
			
			if(!rs) {
				[NSException raise:@"InvalidWebResponseObject" format:@"Probably becouse an action was defined, but returned a nil WebResponse instance", nil];
			} else {
				//Remove body from HEAD requests
				if([method isEqualToString:@"HEAD"]) {
					[rs setBody:nil];
				}
			}
						
			FCGX_SetExitStatus(rs.code, request.out);
			
			pthread_mutex_lock(&counts_mutex);
			FCGX_FPrintF(request.out, "%s", [[rs dump] bytes]);
			pthread_mutex_unlock(&counts_mutex);
			
			float t = -[start timeIntervalSinceNow];			
			NSLog(@"FOWResolver: request [%@][%@] completed in [%.4f] on thread [%@]", rq.method, rq.uri,  t, [[[NSThread currentThread] threadDictionary] valueForKey:@"location"]);
		} @catch (NSException *exception) {
			FCGX_SetExitStatus(500, request.out);
			NSMutableString *err = [NSMutableString stringWithFormat:
					@"Content-type: text/html\n\n\
									<html><head><title>Froth Exception</title></head> \
									<body>Uncaught exception: <strong>%@</strong>: <pre>%@</pre>\nStack trace:<ul>\n", [exception name], [exception reason]];
			[err appendFormat:@"</ul><br>UserInfo:%@", [exception userInfo]];
			[err appendString:@"</body></html>"];
			
			NSLog(@"******** FOWFastCgiController: Recovery from exception [%@] [%@]", [exception name], [exception description]);
			
			pthread_mutex_lock(&counts_mutex);
			FCGX_FPrintF(request.out, "%s", [err UTF8String]);
			pthread_mutex_unlock(&counts_mutex);
		} @finally {
			[rq release];
		}
		
		FCGX_Finish_r(&request);
		//Unlocking the thread hear causes mutli-threading to be locked!
		
		[pool drain];
	}
	
	[gpool drain];
}

#pragma mark -
#pragma mark PureC

- (void)processRequests_c {
	int i;
	int res;
	pthread_t thr[threadCount];
	for(i=1; i<threadCount; i++) {
		res = pthread_create(&thr[i], NULL, r_thread_accept, (void*)[froth_dic([NSNumber numberWithInt:i], @"threadIndex", webApp, @"application") retain]);
		if (res) {
			printf("ERROR; return code from pthread_create() is %d\n", res);
			exit(-1);
		}
		/*[NSThread detachNewThreadSelector:@selector(threadTask:)
								 toTarget:self
							   withObject:[NSNumber numberWithInt:i]];*/
	}
	
	//The main thread needs to stay working as well.
	//[self threadTask:[NSNumber numberWithInt:i]];
	r_thread_accept((void*)froth_dic([NSNumber numberWithInt:0], @"threadCount", webApp, @"application"));
}


@end
