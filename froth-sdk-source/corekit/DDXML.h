#ifndef __APPLE__

#import "DDXMLNode.h"
#import "DDXMLElement.h"
#import "DDXMLDocument.h"

#ifndef NSXMLNode
#define NSXMLNode DDXMLNode
#endif
#ifndef NSXMLElement
#define NSXMLElement DDXMLElement
#endif
#ifndef NSXMLDocument
#define NSXMLDocument DDXMLDocument
#endif

#endif