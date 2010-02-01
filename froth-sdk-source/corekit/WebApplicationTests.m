//
//  WebApplicationTests.m
//  FrothKit
//
//  Created by Allan Phillips on 15/01/10.
//  Copyright 2010 Thinking Code Software Inc. All rights reserved.
//

#import "WebApplicationTests.h"
#import "WebApplication.h"

@implementation WebApplicationTests

- (NSArray*)tests {
	return [NSArray arrayWithObjects:@"test_deploymentMode", 
			@"test_deploymentUriPath",
			@"test_deploymentConfigDictionary",
			@"test_frameworkInfoPlistLookup", nil];
}

- (void)test_deploymentMode {
	FRPass(@"Deployment mode is :%@", [WebApplication deploymentMode]);
	NSLog(@"hereMode");
}

- (void)test_deploymentUriPath {
	FRPass(@"Deployment path is :%@", [WebApplication deploymentUriPath]);
	NSLog(@"herePath");
}

- (void)test_deploymentConfigDictionary {
	FRPass(@"Deployment conf dict is :%@", [WebApplication deploymentConfigDictionary]);
	NSLog(@"hereDict");
}

//Hmm, why is this here... not related to WebApplication.
- (void)test_frameworkInfoPlistLookup {
	FRPass(@"Deployment conf dict is :%@", [[NSBundle bundleForClass:[WebApplication class]] infoDictionary]);
}

@end
