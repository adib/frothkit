//
//  NSURLConnection+FoundationCompletions.m
//  FrothKit
//
//  Created by Allan Phillips on 19/11/09.
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

#import "NSURLConnection+FoundationCompletions.h"
#import <Foundation/NSHTTPURLResponse.h>

#include <curl/curl.h>
#include <curl/easy.h>

struct MemoryStruct {
	char *memory;
	size_t size;
};

static void *myrealloc(void *ptr, size_t size);

static void *myrealloc(void *ptr, size_t size)
{
	/* There might be a realloc() out there that doesn't like reallocing
     NULL pointers, so we take care of it here */ 
	if(ptr)
		return realloc(ptr, size);
	else
		return malloc(size);
}

static size_t
WriteMemoryCallback(void *ptr, size_t size, size_t nmemb, void *data)
{
	size_t realsize = size * nmemb;
	struct MemoryStruct *mem = (struct MemoryStruct *)data;
	
	mem->memory = myrealloc(mem->memory, mem->size + realsize + 1);
	if (mem->memory) {
		memcpy(&(mem->memory[mem->size]), ptr, realsize);
		mem->size += realsize;
		mem->memory[mem->size] = 0;
	}
	return realsize;
}

//Simple wrapper as cocotron does not implement this, this should fully support all of NSMutableURLResponse
@interface NSURLResponse_Froth : NSHTTPURLResponse {
	int m_status;
}

@end

@implementation NSURLResponse_Froth

- (id)initWithStatusCode:(NSInteger)code {
	if(self = [super init]) {
		m_status = code;
	}
	return self;
}

- (NSInteger)statusCode {
	return m_status;
}

@end


@implementation NSURLConnection (FoundationCompletions)

+ (NSData *)sendSynchronousRequest:(NSURLRequest *)request returningResponse:(NSURLResponse **)responsep error:(NSError **)errorp {
	
	struct MemoryStruct response;
	response.memory = NULL;
	response.size = 0;
	
	struct curl_slist *slist = NULL;
	
	CURL* chandle = curl_easy_init();
	curl_easy_setopt(chandle, CURLOPT_URL, [[[request URL] absoluteString] UTF8String]);
	
	NSString* method = [request HTTPMethod];
	if([method isEqualToString:@"GET"]) {
		curl_easy_setopt(chandle, CURLOPT_HTTPGET, 1);
	} else if([method isEqualToString:@"POST"]) {
		curl_easy_setopt(chandle, CURLOPT_POSTFIELDS, [[request HTTPBody] bytes]);
		curl_easy_setopt(chandle, CURLOPT_POSTFIELDSIZE, [[request HTTPBody] length]);
	} else if([method isEqualToString:@"PUT"]) {
		curl_easy_setopt(chandle, CURLOPT_UPLOAD, 1);
		curl_easy_setopt(chandle, CURLOPT_READDATA, [[request HTTPBody] bytes]); //Not sure if this will work for puts...
		curl_easy_setopt(chandle, CURLOPT_INFILESIZE, [[request HTTPBody] length]);
	} else if([method isEqualToString:@"DELETE"]) {
		 curl_easy_setopt(chandle, CURLOPT_CUSTOMREQUEST, "DELETE");
	}
	
	//TODO: Create a read function and pointer for reading post/put data
	NSDictionary* headers = [request allHTTPHeaderFields];
	NSArray* hkeys = [headers allKeys];
	if([hkeys count]) {
		for(NSString*headerKey in hkeys) {
			NSString*hvalue = [headers valueForKey:headerKey];
			if((NSNull*)hvalue != [NSNull null]) {
				slist = curl_slist_append(slist, [[NSString stringWithFormat:@"%@: %@", headerKey, hvalue] UTF8String]);
			} else {
				slist = curl_slist_append(slist, [[NSString stringWithFormat:@"%@:", headerKey] UTF8String]);
			}
		}
		curl_easy_setopt(chandle, CURLOPT_HTTPHEADER, slist);
	}
		
	curl_easy_setopt(chandle, CURLOPT_WRITEFUNCTION, WriteMemoryCallback);
	curl_easy_setopt(chandle, CURLOPT_WRITEDATA, (void *)&response);
	
	NSLog(@"getting here?");
	if(curl_easy_perform(chandle) == 0) { //Success
		curl_slist_free_all(slist);
		
		long code;
		curl_easy_getinfo(chandle, CURLINFO_RESPONSE_CODE, &code);
		NSLog(@"response code:%i",code);
		
		//Simple response based on status code.
		///--- Does not work...
		//*responsep = [[NSURLResponse_Froth alloc] initWithStatusCode:code];
		
		//TODO add header response as well...
		
		curl_easy_cleanup(chandle);
		
		NSData* data = [NSData dataWithBytes:(void*)response.memory length:response.size];
		return data;
	} else {
		NSLog(@"--- NSURLConnection+LibCurl Wrapper Error ---");
		curl_slist_free_all(slist);
		curl_easy_cleanup(chandle);
		*errorp = [NSError errorWithDomain:@"FrothNSURLConnectionDomain" code:9231 userInfo:nil];
		return NULL;
	}
}

@end
