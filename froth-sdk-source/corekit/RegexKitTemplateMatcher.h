//
//  RegexKitTemplateMatcher.h
//
//  Created by Matt Gemmell on 12/05/2008.
//  Copyright 2008 Instinctive Code. All rights reserved.
//

#import "MGTemplateEngine.h"
//#import <RegexKit/RegexKit.h>
#import "objpcre.h"

/*
 This is an example Matcher for MGTemplateEngine, implemented using RegexKit.
 
 To use this matcher, you'll need to install RegexKit, link your target to it, and 
 ensure it's copied into your built application. The RegexKit documentations explains 
 how to do all this. Get RegexKit here:
 http://regexkit.sourceforge.net/
 
 Other matchers can easily be implemented using the MGTemplateEngineMatcher protocol,
 if you prefer to use another regex framework, or use another matching method entirely.
 */

@interface RegexKitTemplateMatcher : NSObject <MGTemplateEngineMatcher> {
	MGTemplateEngine *engine;
	NSString *markerStart;
	NSString *markerEnd;
	NSString *exprStart;
	NSString *exprEnd;
	NSString *filterDelimiter;
	NSString *templateString;
	ObjPCRE *regex;
}

@property(assign) MGTemplateEngine *engine; // weak ref
@property(retain) NSString *markerStart;
@property(retain) NSString *markerEnd;
@property(retain) NSString *exprStart;
@property(retain) NSString *exprEnd;
@property(retain) NSString *filterDelimiter;
@property(retain) NSString *templateString;
@property(retain) ObjPCRE *regex;

+ (RegexKitTemplateMatcher *)matcherWithTemplateEngine:(MGTemplateEngine *)theEngine;

- (NSArray *)argumentsFromString:(NSString *)argString;

@end
