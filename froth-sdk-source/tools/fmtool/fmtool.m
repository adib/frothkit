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

#import <stdio.h>

#define FROTH_CONFIG_DIR @"/var/froth/config/httpd"
#define FROTH_WEBAPP_PATH @"/var/froth/apps/%@/%@.webApp"
#define FROTH_STATIC_PATH @"/var/froth/apps/%@/%@.webApp/static"
#define FROTH_CONFIG_TEMPLATE @"/var/froth/config/confTemplate.conf"
#define FROTH_ROOT_WEBAPPS @"/var/froth/apps"

#ifdef __APPLE__
#define FROTH_USERS_DIR @"/Users/"
#else
#define FROTH_USERS_DIR @"/home/"
#endif

void f_wait(double time);

/* 
	All commands typically take -[option] [AppName] [Mode]	- if no mode 'release' is used.
*/

/*
	Generates a lighttpd configuration section for the given web app params.
	This searchs first for a 'Deployments.plist' new style configuration useing the following constructed path
	
	if(user == nil)
		path = /var/froth/apps/[mode]/[name].webApp/Contents/Resources/Deployments.plist
	if(file does not exist at path)		
		this uses the old style info.plist method.
 
	\param webApp A NSBundle web app.
	\param mode	The deployment mode corresponding to the Build Configuration Name and Deployments.plist>Mode> record
	\param user A username for user on the machine or null to user /var/froth/apps path.
 
	\returns A generated lighttped configration string from 'confTemplate for given lightted version.
 */
NSString* configurationForWebApp(NSBundle* webApp, NSString* mode, NSString* user);

NSBundle* bundleForWebApp(NSString* name, NSString* mode, NSString* user);

/* TODO: Does not support user dir scheme yet. */
void generateConfigurations();

int startWebApp(NSBundle* webApp, NSString* port, NSString* user);
int stopWebApp(NSBundle* webApp, NSString* port, NSString* user);
int cleanUpPort(NSString* port);
int restartWebApp(NSBundle* webApp, NSString* port, NSString* user);
int consoleAttachForWebApp(NSBundle* webApp, NSString* port, NSString* user);


int main (int argc, const char * argv[]) {
	NSInitializeProcess(argc, argv);
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

	NSString* userName = [NSString stringWithUTF8String:getenv("USER")];
	if([userName isEqualToString:@"root"]) {
		userName = nil;
	}
	
	NSArray* args = [[NSProcessInfo processInfo] arguments];
	NSString* option = nil;
	NSString* webAppName = nil;
	NSString* webAppMode = @"release";
	
	if(args.count>1) {
		option = [args objectAtIndex:1];
	}
	if(args.count>2) {
		webAppName = [args objectAtIndex:2];
	}
	if(args.count>3) {
		webAppMode = [args objectAtIndex:3];
	}
	
	if(!option) {
		printf("FrothMachine Tools Version 0.8.1\n\nFor useage info use fmtool -h\n\n");
	} else if([option isEqualToString:@"-h"]) {
		printf("FrothMachine Tools Version 0.8.1\n");
		printf("-i [WebAppName] [mode] starts a webapp\n");
		printf("-s [WebAppName] [mode] stops a webapp\n");
		printf("-o [WebAppName] [mode] launches a webapp with stout to terminal\n");
		printf("-c Outputs lighttpd configurations for all 'Enabled' webapps on the system for use with lighttpd's 'include_shell' option\n");
	} 
	
	//We need to parse through all web apps installed to generate lighttpd configurations.
	else if([option isEqualToString:@"-c"]) {
		generateConfigurations();
	}
	
	//Lastly
	else {
		NSBundle* webApp = bundleForWebApp(webAppName, webAppMode, userName);
		NSString* port = nil; //Why is this a string?
		NSArray* multiPorts = nil;
		NSDictionary* conf = [NSDictionary dictionaryWithContentsOfFile:froth_str(@"%@/Contents/Resources/Deployments.plist", [webApp bundlePath])];
		if(conf) {
			port = [conf valueForKeyPath:froth_str(@"Modes.%@.Port", webAppMode)];
			if([port rangeOfString:@","].location != NSNotFound) {
				multiPorts = [port componentsSeparatedByString:@","];
				port = [multiPorts objectAtIndex:0];
			}
		} else {
			//Legacy support, single port only...
			port = [[webApp infoDictionary] valueForKey:froth_str(@"froth_port_%@", webAppMode)];
		}
		
		if([option isEqualToString:@"-i"]) {
			if(multiPorts) {
				for(NSString* port in multiPorts) {
					stopWebApp(webApp, port, userName);
					startWebApp(webApp, port, userName);
				}
			} else {
				stopWebApp(webApp, port, userName);
				startWebApp(webApp, port, userName);
			}
		} else if([option isEqualToString:@"-s"]) {
			if(multiPorts) {
				for(NSString* port in multiPorts)
					stopWebApp(webApp, port, userName);
			} else {
				stopWebApp(webApp, port, userName);
			}
		} else if([option isEqualToString:@"-o"]) { //Does not support user paths
			if(multiPorts) {
				for(NSString* port in multiPorts) {
					stopWebApp(webApp, port, userName);
				}
			} else {
				stopWebApp(webApp, port, userName);
			}
		
			
			NSString* binPath = froth_str(@"%@/Contents/Linux/%@", [webApp bundlePath], webAppName);
			NSTask* task = [NSTask launchedTaskWithLaunchPath:binPath arguments:[NSArray arrayWithObjects:port, port, nil]];
			[task waitUntilExit];
		} else if([option isEqualToString:@"-v"]) {
			//A rather hacky way to view the live out of an already running process. Should be cleaned up a bit with a pipe.
			//strace -p [PID] -e write -e write=0 -s 1024
			
			//Format is -v WebApp MODE PORT
			NSString* pt = [args objectAtIndex:4];
			NSData* data = [[NSData alloc] initWithContentsOfFile:froth_str(@"%@.%@.pid", [webApp executablePath], pt)];
			NSString* pid = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
			
			pid = [pid stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			
			NSLog(@"will attach to pid [%@]", pid);
			
			system([froth_str(@"strace -p %@ -e write -e write=0 -s 1024", pid) UTF8String]);	
			
			//NSTask* task = [NSTask launchedTaskWithLaunchPath:binPath arguments:[NSArray arrayWithObjects:port, port, nil]];
			//[task waitUntilExit];
		}
	}

    [pool drain];
    return 0;
}

NSBundle* bundleForWebApp(NSString* name, NSString* mode, NSString* user) {
	NSString* path = nil;
	if(user) {
		path = froth_str(@"%@%@/froth/apps/%@/%@", FROTH_USERS_DIR, user, mode, name);
	} else {
		path = froth_str(FROTH_WEBAPP_PATH, mode, name);
	}
	
	//1, get the bundle for the webapp.
	return [NSBundle bundleWithPath:path];
}

int startWebApp(NSBundle* webApp, NSString* port, NSString* user) {
	printf("+Starting webapp\n\t [%s]:[%s]\n", [port UTF8String], [[webApp executablePath] UTF8String]);
	[NSTask launchedTaskWithLaunchPath:@"/sbin/start-stop-daemon" arguments:[NSArray arrayWithObjects:@"--start", @"--oknodo", @"--exec", [webApp executablePath], @"--make-pidfile", @"--pidfile", froth_str(@"%@.%@.pid", [webApp executablePath], port),  @"-b", @"--", port, port, port, nil]];
	//TODO: replace nstask with system("...")
	f_wait(0.1);
	return 0;
}

//Doesnt actually need 'port'..
int stopWebApp(NSBundle* webApp, NSString* port, NSString* user) {	
	/* NOTE: user paths not yet supported */
	
	//start-stop-daemon --start -x /var/froth/apps/beta/WebAppTemplate.webApp/Contents/Linux/WebAppTemplate -b
	printf("+Stopping webApp\n\t [%s]:[%s]\n", [port UTF8String], [[webApp executablePath] UTF8String]);
		
	//Stop in case its already started.
	[NSTask launchedTaskWithLaunchPath:@"/sbin/start-stop-daemon" arguments:[NSArray arrayWithObjects:@"--stop", @"--oknodo", @"--exec", [webApp executablePath], @"--pidfile", froth_str(@"%@.%@.pid", [webApp executablePath], port), @"", nil]];
	f_wait(0.1);

	//Remove the pid file at [webApp executablePath].$PORT.pid
	remove([froth_str(@"%@.%@.pid", [webApp executablePath], port) UTF8String]);
	
	cleanUpPort(port);
	
	return 0;
}

//Distructive, this is if the port is left hanging for some reason, should be removed...
int cleanUpPort(NSString* port) {
	//Run cleanup script after kill. Fixes http://code.google.com/p/frothkit/issues/detail?id=17 issue with uuid not stopping when new guid is generated.
	[NSTask launchedTaskWithLaunchPath:@"/usr/froth/bin/cleanup_uuid_process" arguments:[NSArray arrayWithObjects:port, port, port, nil]];
	f_wait(0.5);
	return 0;
}

int restartWebApp(NSBundle* webApp, NSString* port, NSString* user) {
	stopWebApp(webApp, port, user);
	return startWebApp(webApp, port, user);
}

//User directories are not supported yet.
NSString* configurationForWebApp(NSBundle* webApp, NSString* mode, NSString* user) {	
	
	NSString* appName = [[webApp bundlePath] lastPathComponent];
	NSArray* ports = nil;
	NSString* port = nil;
	NSString* root = nil;
	NSString* host = nil;
	
	BOOL disabled = FALSE;
	
	NSString* modernConfPath = froth_str(@"%@/Contents/Resources/Deployments.plist", [webApp bundlePath]);
	NSDictionary* conf = [NSDictionary dictionaryWithContentsOfFile:modernConfPath];
	if(conf) {
		port = [conf valueForKeyPath:froth_str(@"Modes.%@.Port", mode)];
		
		if([port rangeOfString:@","].location != NSNotFound) {
			ports = [port componentsSeparatedByString:@","];
			port = [ports objectAtIndex:0];
		} else {
			ports = [NSArray arrayWithObject:port];
		}
		
		root = [conf valueForKeyPath:froth_str(@"Modes.%@.Root", mode)];
		host = [conf valueForKeyPath:froth_str(@"Modes.%@.Host", mode)];
		disabled = [[conf valueForKeyPath:froth_str(@"Modes.%@.Disabled", mode)] boolValue];
	} else {
		//Legacy support, single ports only...
		printf("### LEGACY DEPLOYMENT CONFIGURATIONS ###\n");
		port =	[[webApp infoDictionary] valueForKey:froth_str(@"froth_port_%@", mode)];
		ports = [NSArray arrayWithObject:port];
		
		root =	[[webApp infoDictionary] valueForKey:froth_str(@"froth_root_%@", mode)];
		host =	[[webApp infoDictionary] valueForKey:froth_str(@"froth_host_%@", mode)];
	}
	
	if(!disabled) {
		//Test if host string is regex (has @ prefex)
		NSNumber* hostIsRegex = [NSNumber numberWithBool:NO];
		if([host hasPrefix:@"@"]) {
			hostIsRegex = [NSNumber numberWithBool:YES];
			host = [host substringFromIndex:1];
		}
		
		//Prepare the string for this webapp
		NSString* confTemplate = [NSString stringWithContentsOfFile:FROTH_CONFIG_TEMPLATE encoding:NSUTF8StringEncoding error:nil];
		
		//The data passed to template, appPath appRoot appHost appName appPort appMode
		NSDictionary* dict = froth_dic(port, @"appPort",
									   ports, @"appPorts",
									   root, @"appRoot", 
									   appName, @"appName", 
									   mode, @"appMode", 
									   [webApp bundlePath], @"appPath",
									   host, @"appHost",
									   hostIsRegex, @"hostIsRegex");
		
		MGTemplateEngine* engine = [MGTemplateEngine templateEngine];
		[engine setMatcher:[AGRegexTemplateMatcher matcherWithTemplateEngine:engine]];
		//[engine setDelegate:engine];
		
		NSString* processedConf = [engine processTemplate:confTemplate withVariables:dict];
		
		return processedConf;
	} else {
		return froth_str(@"### %@ [%@] IS DISABLED ###\n", appName, mode);
	}
}

void generateConfigurations() {
	NSFileManager* fm = [NSFileManager defaultManager];
	NSArray* rootDeployModes = [fm directoryContentsAtPath:FROTH_ROOT_WEBAPPS];
	for(NSString* mode in rootDeployModes) {
		NSArray* appBundlePaths = [fm directoryContentsAtPath:froth_str(@"%@/%@", FROTH_ROOT_WEBAPPS, mode)];
		for(NSString* app in appBundlePaths) {
			@try {
				printf("\n#### %s [%s] #####\n", [app UTF8String], [mode UTF8String]);
				
				NSBundle* webApp = bundleForWebApp([app stringByDeletingPathExtension], mode, nil);	//root
				printf("\n\n%s", [configurationForWebApp(webApp, mode, nil) UTF8String]);
			}
			@catch (NSException * e) {
				printf("\n#### %s ####\n", [[e description] UTF8String]);
			}
		}
	}
	printf("\n\n");
}

void f_wait(double time) {
	//Simple wait function f_wait(0.2)
	NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
	NSTimeInterval endTime = startTime + time;
	while([[NSDate date] timeIntervalSince1970] < endTime) {}
}