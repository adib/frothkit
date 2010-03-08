//
//  WebMailer.h
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

#import <Foundation/Foundation.h>

/*! 
	\brief	This uses the embeded python interpreter to send email using a template based design. 
			
			Email templates should have the .email extension. The supplied dictionary to the class methods
			must have at minimal a 'subject' entry and a 'to' entry where the value is a array of email addresses conforming
			to RFC 2822 (Allan Phillips <my@email.com>), plain emails are also supported as per rfc.
 
			Additional entrys can be provided in the dictionary, and will be accessable from the template using the standard
			templating syntex for FrothKit.
 */
@interface WebMailer : NSObject {

}

/*! \brief Sends an email using a template file. This allows for powerful email processing and sending
	\param templateName A template file with extention .email
	\param templData A ns dictionary that will be parsed from the template, it must also contain the following
			values for the engine. 
			- to: NSArray of emails
			- subject: Subject of email
			- from (an optional email to use instead of account address)
*/
+ (void)sendEmailWithTemplate:(NSString*)templateName 
					   dict:(NSDictionary*)templData
				contentType:(NSString*)conType 
				   smtpHost:(NSString*)host
				   smtpUser:(NSString*)user
				   smtpPass:(NSString*)pass;


+ (void)sendEmailWithTemplate:(NSString*)templateName 
						 dict:(NSDictionary*)templData
				  contentType:(NSString*)conType 
					 smtpHost:(NSString*)host
					 smtpUser:(NSString*)user
					 smtpPass:(NSString*)pass
			   attachmentPath:(NSString*)path;

@end
