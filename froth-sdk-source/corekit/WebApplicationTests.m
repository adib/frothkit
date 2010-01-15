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
			@"test_deploymentConfigDictionary", nil];
}

- (void)test_deploymentMode {
	FRPass(@"Deployment mode is :%@", [WebApplication deploymentMode]);
}

- (void)test_deploymentUriPath {
	FRPass(@"Deployment path is :%@", [WebApplication deploymentUriPath]);
}

- (void)test_deploymentConfigDictionary {
	FRPass(@"Deployment conf dict is :%@", [WebApplication deploymentConfigDictionary]);
}

@end
