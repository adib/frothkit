//
//  WAExampleController.m
//  TemplateProject
//

#import "WAExampleController.h"


@implementation WAExampleController

- (id)index:(WebRequest*)req {
	return @"plink";
}

- (id)exampledAction:(WebRequest*)req {
	NSMutableString* out_s = [NSMutableString string];
	[out_s appendFormat:@"<html><body>"];
	[out_s appendFormat:@"<h1>My first <i>great</i> froth web app.</h1>"];
	
	//params ./example/example/[firstParam]/.../[lastParam]
	if([req.params count] > 0 && [[req firstParam] isEqualToString:@"lorum"]) {
		[out_s appendFormat:@"<span>You found the easter egg!</span><br>"];
		[out_s appendFormat:@"<img src='http://farm1.static.flickr.com/43/123380632_2bd133e745.jpg'/>"];
	}
	
	[out_s appendFormat:@"</body></html>"];
	
	//Set the document title for request. (See Layout.html)
	self.pageTitle = @"Example Page";
	
	return out_s;
}

- (id)pageAction:(WebRequest*)req {
	return froth_dic(@"Value Passed in Dictionary to View", @"title");
}

@end
