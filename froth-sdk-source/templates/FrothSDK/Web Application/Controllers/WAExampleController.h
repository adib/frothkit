//
//  WAExampleController.h
//  TemplateProject
//

#import <Foundation/Foundation.h>
#import <Froth/Froth.h>

@interface WAExampleController : WebActiveController {

}

/* Provides an example uri method endpoint ./example/example */
- (id)exampleAction:(WebRequest*)req;

@end
