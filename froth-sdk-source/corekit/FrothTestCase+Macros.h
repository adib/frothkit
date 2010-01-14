/*
 *  FrothTestCase+Macros.h
 *  FrothKit
 *
 *  Created by Allan Phillips on 11/01/10.
 *  Copyright 2010 Thinking Code Software Inc. All rights reserved.
 *
 */

/* Test Assertions (note. these need to be rewrote using something other then exceptions...) */
#define FRAssertNil(obj, description, ...)
#define FRAssertNotNil(obj, description, ...)
#define FRAssertTrue(expression, description, ...)
#define FRAssertFalse(expression, description, ...)
#define FRAssertEqualObjects(obj1, obj2, description, ...)

#define FRFail(description, ...) \
	[self addResult:[NSException exceptionWithName:[NSString stringWithFormat:@"FRAssertFail"] \
														reason:[NSString stringWithFormat:description, ## __VA_ARGS__] \
													  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSStringFromClass([self class]), @"className", [NSString stringWithFormat:@"%s", _cmd], @"methodName", nil]]];

#define FRPass(description, ...) \
	[self addResult:[NSException exceptionWithName:[NSString stringWithFormat:@"FRAssertPass"] \
														reason:[NSString stringWithFormat:description, ## __VA_ARGS__] \
													  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSStringFromClass([self class]), @"className", [NSString stringWithFormat:@"%s", _cmd], @"methodName", nil]]];

