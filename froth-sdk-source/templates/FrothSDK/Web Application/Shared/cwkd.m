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

/*
	This is the main function for Froth WebApps using FastCGI. Basically this just sets up a WebApplication instance that
	the fastcgi component will pass requests to.
 
	Possible args [port] defualt is 9343
 */

#import <signal.h>

#ifndef __APPLE__
#include <python2.6/Python.h>
#else
#include <Python/Python.h>
#endif

/* C Crash handlers */
//TODO: something more gracefull...

//Normal exit
void froth_handle_sigint(int sig) {
	NSLog(@"\nFroth - Safely shutting down....");
	exit(0);
}

//Crash SIGBUS
void froth_handle_sigbus(int sig) {
	NSLog(@"Froth - Ignore sigbus. determining recovery measures...");
	exit(0);
}

int main (int argc, const char * argv[]) {	
	signal(SIGINT, froth_handle_sigint);
	signal(SIGSEGV, froth_handle_sigbus);
	
	//For embeded python interpreter support
	Py_Initialize();
	
#ifndef __APPLE__
	NSInitializeProcess(argc, argv);
#endif
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	NSLog(@"Froth Web Application Server - Version %@", FROTH_VERSION_STRING);
	
	WebApplication *webApp = [[WebApplication alloc] init];
	if(!webApp) 
		NSLog(@"*** Internal error, possibly unable to load libFroth.so");
	
	NSString* port;
	if(argc>0) {
		port = [NSString stringWithFormat:@":%s", argv[1]];
	} else {
		port = @":9343";
	}
	
	NSLog(@"WebApplication: web application [%@] [%@]", [[NSBundle mainBundle] bundleIdentifier], port);
	
	WebFastCgiController *cgi = [[WebFastCgiController alloc] initWithWebApplication:webApp path:port chmod:-1];
	[cgi processRequests];
	
	[webApp release];
	
	NSLog(@"Finalized...");
    [pool drain];
    return 0;
}
