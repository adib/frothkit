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


#define froth_array(value1, ...) [NSArray arrayWithObjects:value1, ## __VA_ARGS__, nil]
#define froth_dic(object1, ...) [NSDictionary dictionaryWithObjectsAndKeys:object1, ## __VA_ARGS__, nil]
#define froth_str(object1, ...) [NSString stringWithFormat:object1, ## __VA_ARGS__]

#define froth_true				[NSNumber numberWithBool:YES]
#define froth_false				[NSNumber numberWithBool:NO]
#define froth_int(value1)		[NSNumber numberWithInt:value1]
#define froth_float(value1)		[NSNumber numberWithFloat:value1]

/*#ifndef __APPLE__
#define TRUE YES
#define FALSE NO
#endif*/