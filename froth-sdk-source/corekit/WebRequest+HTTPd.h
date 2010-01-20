//
//  WebRequest+HTTPd.h
//  FrothKit
//
//  Created by Allan Phillips on 18/01/10.
//  Copyright 2010 Thinking Code Software Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WebMutableRequest.h"

#import <sys/queue.h>
#import <evhttp.h>

@interface WebMutableRequest (HTTPd)

- (id)initWithEVhttp:(struct evhttp_request*)evreq;

@end
