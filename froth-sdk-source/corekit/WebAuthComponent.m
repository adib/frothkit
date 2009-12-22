//
//  WebAuthComponent.m
//  Froth
//
//  Created by Allan Phillips on 16/07/09.
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
#import "WebAuthComponent.h"
#import "froth.h"

@implementation WebAuthComponent

#pragma mark -
#pragma mark Public

+ (NSString*)hash:(NSString*)value withSalt:(NSString*)salt {
	//This uses the same format as cakephp.
	NSString* preHashed = [NSString stringWithFormat:@"%@%@", salt, value];
	NSData* hashData = [preHashed dataUsingEncoding:NSUTF8StringEncoding];
	return [hashData sha1DigestString];
}

#pragma mark -
#pragma mark Internal Actions Overidden from Specified User Controller

/*
 Provides a standard user signin form, this can be customized to specific needs.
 Becouse this is a dynamic replacement for the <Identity>Controller's login
 action stub, the user should implement a <Identity>LoginView template.
 */
- (id)loginAction:(WebRequest*)request withConfiguration:(NSDictionary*)config {
	if([[request method] isEqualToString:@"GET"]) {
		return [NSDictionary dictionary];
	} else {
		NSDictionary* postBody = [request objectValue];
		if(!postBody) {
			return [WebResponse htmlResponseWithBody:@"Auth Failed"];
		}
		
		NSString* user = [postBody valueForKey:@"user"];
		NSString* pass = [postBody valueForKey:@"pass"];
		
		if([user rangeOfString:@"@"].location != NSNotFound) {
			user = [[user componentsSeparatedByString:@"@"] objectAtIndex:0];
		}
		
		NSString* modelName = [config valueForKey:@"model"];
		NSString* modelUserKey = [config valueForKey:@"userKey"];
		NSString* modelPassKey = [config valueForKey:@"passKey"];
		Class modelClass = NSClassFromString(modelName);
		if(!modelClass || !modelUserKey || !modelPassKey) 
			froth_exception(@"InvalidAuthIdentityModel", @"Could not find model named [%@]] for WebAuthComponent", modelName);
		
		id modelObject = [modelClass identityObjectForUser:user];
		
		NSString* hashedPass = [[self class] hash:pass withSalt:TEMP_SITE_SALT];
		
		if([user isEqualToString:[modelObject valueForKey:modelUserKey]] && [hashedPass isEqualToString:[modelObject valueForKey:modelPassKey]] ) {
			//NSLog(@"values... %@", [(WebModelBase*)modelObject dictionaryRepresentation]);
			[request.session setValue:[(WebModelBase*)modelObject dictionaryRepresentation] forKey:@"user"];
			[request.session save];
			
			NSString* redirect_path = [request.session valueForKey:@"pre-auth"];
			[request.session setValue:nil forUndefinedKey:@"pre-auth"];
			[request.session save];
			
			NSLog(@"pre auth path:%@", redirect_path);
			
			//Send the user to the website root.
			if(!redirect_path) 
				redirect_path = [NSString stringWithFormat:@"http://%@/home", [[request headers] valueForKey:@"SERVER_NAME"]];
			
			return [WebResponse redirectResponseWithUrl:redirect_path];
		} else {
			return [WebResponse htmlResponseWithBody:@"Auth Failed"];
		}
	}
}

- (id)logoutAction:(WebRequest*)request {
	[request.session setValue:nil forKey:@"user"];
	[request.session save];
	return [WebResponse redirectResponseWithUrl:@"/"];
}

#pragma mark -
#pragma mark WebComponent

- (id)preProcessRequest:(WebRequest*)request forController:(id <WebActionController>)controller withConfiguration:(NSDictionary*)config {
	
	if((NSNull*)config == [NSNull null]) {
		if(![request.session valueForKey:@"user"]) {
			
			//Setup the possible redirect back after auth
			[request.session setValue:[request.headers valueForKey:@"SCRIPT_URI"] forKey:@"pre-auth"];
			[request.session save];
			
			return [WebResponse redirectResponseWithUrl:[NSString stringWithFormat:@"http://%@", [request.headers valueForKey:@"SERVER_NAME"]]];
		} else {
			return nil;
		}
	}
	
	/*
		Handle built in supplied methods specific to the specified <Identity>Controller
	 */
	NSString* identityController = [config valueForKey:@"controller"];
	if([request.controller isEqualToString:identityController]) {
		if([request.action isEqualToString:@"login"]) {
			return [self loginAction:request withConfiguration:config];
		} else if([request.action isEqualToString:@"logout"]) {
			return [self logoutAction:request];
		}
	}
	
	NSArray* allowed = [config objectForKey:@"allow"];
	NSLog(@"WebAuthComponent: Current Session User [%@]", [request.session username]);
	if(![allowed containsObject:request.action] && ![request.session valueForKey:@"user"]) {
		
		//Possible redirect on save
		[request.session setValue:[request.headers valueForKey:@"SCRIPT_URI"] forKey:@"pre-auth"];
		[request.session save];
		
		return [WebResponse redirectResponseWithUrl:[NSString stringWithFormat:@"http://%@", [request.headers valueForKey:@"SERVER_NAME"]]];
	}
	
	return nil;
}

- (id)postProcessResponse:(id)response fromRequest:(WebRequest*)request ofController:(id <WebActionController>)controller withConfiguration:(NSDictionary*)config {
	return response;
}


@end
