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

#import <Foundation/Foundation.h>
#import "WebApplication.h"

#include "fcgiapp.h"

@interface WebFastCgiController : NSObject {
	WebApplication* webApp;
	
	int sock;
	int threadCount;
}

@property (readwrite,assign) int threadCount;

//WebApplication should implement - (WebResponse*)handle:(WebRequest*)request;
- (id)initWithWebApplication:(WebApplication*)app path:(NSString*)path chmod:(int)c;

- (void)dealloc;

- (void)processRequests;
- (void)threadTask:(id)unused;

@end;
