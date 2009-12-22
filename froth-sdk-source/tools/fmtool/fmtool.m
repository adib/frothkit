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

#define FROTH_CONFIG_DIR @"/var/froth/config/httpd"
#define FROTH_WEBAPP_PATH @"/var/froth/apps/%@/%@.webApp"
#define FROTH_STATIC_PATH @"/var/froth/apps/%@/%@.webApp/static"
#define FROTH_CONFIG_TEMPLATE @"/var/froth/config/confTemplate.conf"

void f_wait(double time);

int prepareWebApp(NSString* name, NSString* mode);

int main (int argc, const char * argv[]) {
	NSInitializeProcess(argc, argv);
	
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	NSArray* args = [[NSProcessInfo processInfo] arguments];
	
	if(argc < 2) {
		printf("FrothMachine Tools V.1\nfmtool useage info use frmtool -h\n");
	} else if([[args objectAtIndex:1] isEqualToString:@"-h"]) {
		printf("FrothMachine Tools Version 1.0\n");
		printf("-i [WebAppName] [mode] install a webapp and prepare is lighttpd conf. Also restarts lighttpd and webapp.\n");
		printf("-s [WebAppName] [mode] stops a webapp\n");
		printf("-r [WebAppName] [mode] starts a webapp\n");
	} else if([[args objectAtIndex:1] isEqualToString:@"-i"]) {
		prepareWebApp([args objectAtIndex:2], [args objectAtIndex:3]);
	}
	
    // insert code here...
    [pool drain];
    return 0;
}

//Name, product name for webapp. Mode, the build configuration for webapp, for deploy, production...
int prepareWebApp(NSString* name, NSString* mode) {
	printf("Preparing Web App [%s:%s]\n", [name UTF8String], [mode UTF8String]);
	
	NSString* path = froth_str(FROTH_WEBAPP_PATH, mode, name);
	
	//1, get the bundle for the webapp.
	NSBundle* webApp = [NSBundle bundleWithPath:path];
	
	//TODO: If port is not assigned we need to pick an open port on the server and use that.
	NSString* port =	[[webApp infoDictionary] valueForKey:froth_str(@"froth_port_%@", mode)];
	NSString* root =	[[webApp infoDictionary] valueForKey:froth_str(@"froth_root_%@", mode)];
	NSString* host =	[[webApp infoDictionary] valueForKey:froth_str(@"froth_host_%@", mode)];
	
	//Prepare the .conf file for this webapp,
	//currently this just overwrites the old ones.
	NSString* confTemplate = [NSString stringWithContentsOfFile:FROTH_CONFIG_TEMPLATE encoding:NSUTF8StringEncoding error:nil];
	
	//The data passed to template, appPath appRoot appHost appName appPort appMode
	NSDictionary* dict = froth_dic(port, @"appPort", 
								   root, @"appRoot", 
								   name, @"appName", 
								   mode, @"appMode", 
								   path, @"appPath",
								   host, @"appHost");
	
	MGTemplateEngine* engine = [MGTemplateEngine templateEngine];
	[engine setMatcher:[AGRegexTemplateMatcher matcherWithTemplateEngine:engine]];
	//[engine setDelegate:engine];
	
	NSString* processedConf = [engine processTemplate:confTemplate withVariables:dict];
	[processedConf writeToFile:froth_str(@"%@/%@_%@.conf", FROTH_CONFIG_DIR, name, mode) atomically:YES encoding:NSUTF8StringEncoding error:nil];
	
	//Launch or restart the webapp.
	//start-stop-daemon --start -x /var/froth/apps/beta/WebAppTemplate.webApp/Contents/Linux/WebAppTemplate -b
	printf("+Initalize httpd fastcgi connection to [%s] with root [%s] at loc [%s]\n", [port UTF8String], [root UTF8String], [[webApp executablePath] UTF8String]);
	
	//Stop in case its already started.
	printf("+force a gracefull shutdown\n");
	[NSTask launchedTaskWithLaunchPath:@"/sbin/start-stop-daemon" arguments:[NSArray arrayWithObjects:@"--stop", @"--oknodo", @"--exec", [webApp executablePath], @"", nil]];
	f_wait(0.4);
	
	printf("+starting webapp\n");
	[NSTask launchedTaskWithLaunchPath:@"/sbin/start-stop-daemon" arguments:[NSArray arrayWithObjects:@"--start", @"--oknodo", @"--exec", [webApp executablePath], @"-b", @"--", port, port, port, nil]];

	//Now relaunch lighttpd
	//[NSTask launchedTaskWithLaunchPath:@"/etc/init.d/lighttpd" arguments:[NSArray arrayWithObjects:@"restart", @"restart", nil]];
	
	return 0;
}

void f_wait(double time) {
	//Simple wait function f_wait(0.2)
	NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
	NSTimeInterval endTime = startTime + time;
	while([[NSDate date] timeIntervalSince1970] < endTime) {}
}