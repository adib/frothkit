/*
 *  FrothTestCase+Macros.h
 *  FrothKit
 *
 *  Created by Allan Phillips on 11/01/10.
 *  Copyright 2010 Thinking Code Software Inc. All rights reserved.
 *
 */

/* Test Assertions (note. these need to be rewrote using something other then exceptions...) */

//fail on not nil
#define FRAssertNil(a1, description, ...)

//fail on nil
#define FRAssertNotNil(a1, description, ...) \
	@try {\
		id a1value = (a1); \
		if (a1value == nil) { \
			[self addResult:[NSException exceptionWithName:[NSString stringWithFormat:@"FRAssertFail"] \
			reason:[NSString stringWithFormat:description, ## __VA_ARGS__] \
			userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSStringFromClass([self class]), @"className", [NSString stringWithFormat:@"%s", _cmd], @"methodName", [NSString stringWithFormat:@"%i", __LINE__], @"line", nil]]];	 \
		} \
	}\
	@catch (id anException) {\
		[self addResult:[NSException exceptionWithName:[NSString stringWithFormat:@"FRAssertFail"] \
		reason:[NSString stringWithFormat:description, ## __VA_ARGS__] \
		userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSStringFromClass([self class]), @"className", [NSString stringWithFormat:@"%s", _cmd], @"methodName", [NSString stringWithFormat:@"%i", __LINE__], @"line", nil]]];	 \
	}\

//Fail on not equal, returns
#define FRAssertEquals(a1, a2, description, ...) \
	if (@encode(__typeof__(a1)) != @encode(__typeof__(a2))) { \
		[self addResult:[NSException exceptionWithName:[NSString stringWithFormat:@"FRAssertFail"] \
			reason:[NSString stringWithFormat:description, ## __VA_ARGS__] \
			userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSStringFromClass([self class]), @"className", [NSString stringWithFormat:@"%s", _cmd], @"methodName", [NSString stringWithFormat:@"%i", __LINE__], @"line", nil]]];	 \
		return; \
	} \
	else { \
		__typeof__(a1) a1value = (a1); \
		__typeof__(a2) a2value = (a2); \
		NSValue *a1encoded = [NSValue value:&a1value withObjCType: @encode(__typeof__(a1))]; \
		NSValue *a2encoded = [NSValue value:&a2value withObjCType: @encode(__typeof__(a2))]; \
		if (![a1encoded isEqualToValue:a2encoded]) { \
			[self addResult:[NSException exceptionWithName:[NSString stringWithFormat:@"FRAssertFail"] \
			reason:[NSString stringWithFormat:description, ## __VA_ARGS__] \
			userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSStringFromClass([self class]), @"className", [NSString stringWithFormat:@"%s", _cmd], @"methodName", [NSString stringWithFormat:@"%i", __LINE__], @"line", nil]]];	 \
			return; \
		} \
	} \


//Fail on false
#define FRAssertTrue(expression, description, ...) \
	if(!expression) {	\
		[self addResult:[NSException exceptionWithName:[NSString stringWithFormat:@"FRAssertFail"] \
			reason:[NSString stringWithFormat:description, ## __VA_ARGS__] \
			userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSStringFromClass([self class]), @"className", [NSString stringWithFormat:@"%s", _cmd], @"methodName", [NSString stringWithFormat:@"%i", __LINE__], @"line", nil]]];	 \
			return; \
	} \

//Fail on true
#define FRAssertFalse(expression, description, ...) \
	if(expression) {	\
		[self addResult:[NSException exceptionWithName:[NSString stringWithFormat:@"FRAssertFail"] \
												reason:[NSString stringWithFormat:description, ## __VA_ARGS__] \
											  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSStringFromClass([self class]), @"className", [NSString stringWithFormat:@"%s", _cmd], @"methodName", [NSString stringWithFormat:@"%i", __LINE__], @"line", nil]]];	 \
		return; \
	} \

// fail on not equals
#define FRAssertNotEqual(a1, a2, description, ...) \
	if (@encode(__typeof__(a1)) == @encode(__typeof__(a2))) { \
		[self addResult:[NSException exceptionWithName:[NSString stringWithFormat:@"FRAssertFail"] \
		reason:[NSString stringWithFormat:description, ## __VA_ARGS__] \
		userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSStringFromClass([self class]), @"className", [NSString stringWithFormat:@"%s", _cmd], @"methodName", [NSString stringWithFormat:@"%i", __LINE__], @"line", nil]]];	 \
		return; \
	} \
	else { \
		__typeof__(a1) a1value = (a1); \
		__typeof__(a2) a2value = (a2); \
		NSValue *a1encoded = [NSValue value:&a1value withObjCType: @encode(__typeof__(a1))]; \
		NSValue *a2encoded = [NSValue value:&a2value withObjCType: @encode(__typeof__(a2))]; \
		if ([a1encoded isEqualToValue:a2encoded]) { \
			[self addResult:[NSException exceptionWithName:[NSString stringWithFormat:@"FRAssertFail"] \
			reason:[NSString stringWithFormat:description, ## __VA_ARGS__] \
			userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSStringFromClass([self class]), @"className", [NSString stringWithFormat:@"%s", _cmd], @"methodName", [NSString stringWithFormat:@"%i", __LINE__], @"line", nil]]];	 \
			return; \
		} \
	} \

//Fail with message (does not return)
#define FRFail(description, ...) \
	[self addResult:[NSException exceptionWithName:[NSString stringWithFormat:@"FRAssertFail"] \
														reason:[NSString stringWithFormat:description, ## __VA_ARGS__] \
													  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSStringFromClass([self class]), @"className", [NSString stringWithFormat:@"%s", _cmd], @"methodName", nil]]];
//Pass with message (does not reaturn)
#define FRPass(description, ...) \
	[self addResult:[NSException exceptionWithName:[NSString stringWithFormat:@"FRAssertPass"] \
														reason:[NSString stringWithFormat:description, ## __VA_ARGS__] \
													  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSStringFromClass([self class]), @"className", [NSString stringWithFormat:@"%s", _cmd], @"methodName", nil]]];

