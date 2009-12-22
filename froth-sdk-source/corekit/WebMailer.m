//
//  WebMailer.m
//  FrothKit
//
//  Created by Allan Phillips on 17/11/09.
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


#import "WebMailer.h"
#import "froth.h"

#ifndef __APPLE__
#include <python2.6/Python.h>
#else
#include <Python/Python.h>
#endif

@implementation WebMailer

+ (void)sendEmailWithTemplate:(NSString*)templateName 
					   dict:(NSDictionary*)templData
				contentType:(NSString*)conType 
				   smtpHost:(NSString*)host
				   smtpUser:(NSString*)user
				   smtpPass:(NSString*)pass 
{
	
	PyObject *py_smtpUser;
	PyObject *py_smtpPass;
	PyObject *py_smtpHost;
	PyObject *py_from;
	PyObject *py_subject;
	PyObject *py_body;
	//PyObject *py_type;
	
	NSArray* to = [templData objectForKey:@"to"];
	if(!to) {
		froth_exception(@"WebMailerException", @"no to provided in dict NSDictionary object");
	}
	
	NSString* subject;
	if(!(subject = [templData valueForKey:@"subject"])) {
		froth_exception(@"WebMailerException", @"no subject key/value supplied with mail templData attribute");
	}
	
	NSString* from;
	if(!(from = [templData valueForKey:@"from"])) {
		from = user;
	}
	
	py_smtpHost = PyString_FromString([host UTF8String]);
	py_smtpUser = PyString_FromString([user UTF8String]);
	py_smtpPass = PyString_FromString([pass UTF8String]);
	
	py_from = PyString_FromString([from UTF8String]);
	py_subject = PyString_FromString([subject UTF8String]);
	
	//Get template from the app bundle, should have a .email extention
	NSBundle* bundle = [NSBundle mainBundle];

	if(!bundle) {
		froth_exception(@"WebMailerException", @"Unable to load bundle for action controller");
	}
	NSString* templatePath = [bundle pathForResource:froth_str(@"%@.email", templateName) ofType:nil];
	if(!templatePath) {
		froth_exception(@"WebMailerException", froth_str(@"No template with name %@[.email] found in webApp bundle", templateName));
	}
	NSString* template = [NSString stringWithContentsOfFile:templatePath encoding:NSUTF8StringEncoding error:nil];
	if(!template) {
		froth_exception(@"WebMailerException", froth_str(@"Unable to load email template %@[.email] - with unknown reason", templateName));
	}
	
	MGTemplateEngine* engine = [MGTemplateEngine templateEngine];
	[engine setDelegate:engine];
	[engine setMatcher:[AGRegexTemplateMatcher matcherWithTemplateEngine:engine]];
	
	NSString* bodyStr = [engine processTemplate:template withVariables:templData];
	if(!bodyStr) {
		froth_exception(@"WebMailerException", @"And error occred processing the email template");
	}
	py_body = PyString_FromString([bodyStr UTF8String]);
	
	//Get the python 'mail' function from our /usr/froth/bin/mailer.py code. and Run the file to so we can get its defined functions
	FILE* mailerFile = fopen("/usr/froth/bin/mailer.py", "r");
	PyRun_SimpleFile(mailerFile, "mailer.py");
	
	//Get the main environment
	PyObject* py_main = PyImport_AddModule("__main__");
	PyObject* py_main_dict = PyModule_GetDict(py_main);
	
	//Get a reference to our mail function (this should be made constant for speed).
	PyObject* py_func = PyDict_GetItemString(py_main_dict, "mail");
	
	PyObject* py_to;
	for(NSString* email in to) {
		NSLog(@"Will send email to:%@", to);
		
		py_to = PyString_FromString([email UTF8String]);
		
		PyObject* fargs = PyTuple_New(8);
		PyTuple_SET_ITEM(fargs, 0, py_to);
		PyTuple_SET_ITEM(fargs, 1, py_from);
		PyTuple_SET_ITEM(fargs, 2, py_subject);
		PyTuple_SET_ITEM(fargs, 3, py_body);
		PyTuple_SET_ITEM(fargs, 4, Py_None);
		PyTuple_SET_ITEM(fargs, 5, py_smtpHost);
		PyTuple_SET_ITEM(fargs, 6, py_smtpUser);
		PyTuple_SET_ITEM(fargs, 7, py_smtpPass);
		
		PyObject_CallObject(py_func, fargs);
	}
}

+ (void)sendEmailWithTemplate:(NSString*)templateName 
						 dict:(NSDictionary*)templData
				  contentType:(NSString*)conType 
					 smtpHost:(NSString*)host
					 smtpUser:(NSString*)user
					 smtpPass:(NSString*)pass
			   attachmentPath:(NSString*)path 
{
	PyObject *py_smtpUser;
	PyObject *py_smtpPass;
	PyObject *py_smtpHost;
	PyObject *py_from;
	PyObject *py_subject;
	PyObject *py_body;
	//PyObject *py_type;
	PyObject *py_attach;
	
	NSArray* to = [templData objectForKey:@"to"];
	if(!to) {
		froth_exception(@"WebMailerException", @"no to provided in dict NSDictionary object");
	}
	
	NSString* from;
	if(!(from = [templData valueForKey:@"from"])) {
		from = user;
	}
	
	py_smtpHost = PyString_FromString([host UTF8String]);
	py_smtpUser = PyString_FromString([user UTF8String]);
	py_smtpPass = PyString_FromString([pass UTF8String]);
	
	py_from = PyString_FromString([from UTF8String]);
	py_subject = PyString_FromString([[templData valueForKey:@"subject"] UTF8String]);
	
	if(path) {
		py_attach = PyString_FromString([path UTF8String]);
	} else {
		py_attach = Py_None;
	}
	
	//Get template from the app bundle, should have a .email extention
	//#ifndef __APPLE__
	NSBundle* bundle = [NSBundle mainBundle];
	//#else
	//	NSBundle* bundle =	[NSBundle bundleForClass:[controller class]];
	//#endif
	if(!bundle) {
		froth_exception(@"WebMailerException", @"Unable to load bundle for action controller");
	}
	NSString* templatePath = [bundle pathForResource:froth_str(@"%@.email", templateName) ofType:nil];
	if(!templatePath) {
		froth_exception(@"WebMailerException", froth_str(@"No template with name %@[.email] found in webApp bundle", templateName));
	}
	NSString* template = [NSString stringWithContentsOfFile:templatePath encoding:NSUTF8StringEncoding error:nil];
	if(!template) {
		froth_exception(@"WebMailerException", froth_str(@"Unable to load email template %@[.email] - with unknown reason", templateName));
	}
	
	MGTemplateEngine* engine = [MGTemplateEngine templateEngine];
	[engine setDelegate:engine];
	[engine setMatcher:[AGRegexTemplateMatcher matcherWithTemplateEngine:engine]];
	
	NSString* bodyStr = [engine processTemplate:template withVariables:templData];
	if(!bodyStr) {
		froth_exception(@"WebMailerException", @"And error occred processing the email template");
	}
	py_body = PyString_FromString([bodyStr UTF8String]);
	
	//Get the python 'mail' function from our /usr/froth/bin/mailer.py code. and Run the file to so we can get its defined functions
	FILE* mailerFile = fopen("/usr/froth/bin/mailer.py", "r");
	PyRun_SimpleFile(mailerFile, "mailer.py");
	
	//Get the main environment
	PyObject* py_main = PyImport_AddModule("__main__");
	PyObject* py_main_dict = PyModule_GetDict(py_main);
	
	//Get a reference to our mail function (this should be made constant for speed).
	PyObject* py_func = PyDict_GetItemString(py_main_dict, "mail");
	
	PyObject* py_to;
	for(NSString* email in to) {
		NSLog(@"Will send email to:%@", to);
		
		py_to = PyString_FromString([email UTF8String]);
		
		PyObject* fargs = PyTuple_New(8);
		PyTuple_SET_ITEM(fargs, 0, py_to);
		PyTuple_SET_ITEM(fargs, 1, py_from);
		PyTuple_SET_ITEM(fargs, 2, py_subject);
		PyTuple_SET_ITEM(fargs, 3, py_body);
		PyTuple_SET_ITEM(fargs, 4, py_attach);
		PyTuple_SET_ITEM(fargs, 5, py_smtpHost);
		PyTuple_SET_ITEM(fargs, 6, py_smtpUser);
		PyTuple_SET_ITEM(fargs, 7, py_smtpPass);
		
		PyObject_CallObject(py_func, fargs);
	}	
}

@end
