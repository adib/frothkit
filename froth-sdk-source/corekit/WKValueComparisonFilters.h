//
//  WKStringCompairFilter.h
//  Froth
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
#import "MGTemplateFilter.h"

/*! 
	\brief	Provide template function/filters to compair two object and return a result
	\detail	string_is_equal			"string-one"
				string_has_prefix		"prefix"
				string_has_suffix		"suffix"
				string_contains			"substring"
				date_is_equal			"day | year | month | hour | minute | complete" "date-one" "date-two"
				date_greater_than		"greater-date" "lesser-date"
				date_in_current_week	"Sunday ... Day to start" "date"
				date_is_today	
				date_is_from_today		"+-int from today"
 */
				
@interface WKValueComparisonFilters : NSObject <MGTemplateFilter> {

}

@end
