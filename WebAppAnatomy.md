# Background #

This document provides a basic description of a froth web application. For complete documentation details, uses should consult the official api documentation. Also the tutorial will provide a quick walkthrough of the procedure of web development with froth.

# Development Details #

_Note: Later development should remove the requirement to prefix controller classes with WA**and suffix with**Controller._

**Model**
Froth provides a simple model layer that abstracts the backing database from the model. A Model class must inherit from WebModelBase. This abstract root provides powerful model features including, serialization to xml and json, memcache support (coming soon) as well as integration with the backing DataSource providers. Froth includes data providers for Memory, MySql and Amazon's SimpleDB. Other data sources can be added my implementing the data source protocol. Froth model classes don't have to specify the fields of the model, as access to model data can be via  -setValue:forKey and corresponding -valueForKey:. WebModelBase automatically maps method accessor and gettor methods so all that is needed is including the method names in the class interface to illuminate compiler warnings.

**Controller**
Web applications revolve around multiple controller classes. Froth is highly dependent on the nomenclature subclasses and method names to provide a standard way of handling requests. A single instance method is used for each request _method_ mapped from the url. The method takes one parameter, an instance of WebRequest that wraps the http request and provides convenience methods for accessing the decoded request data. The objc method then does the appropriate action and returns one of, a NSString, a subclass of NSObject or a subclass of WebResponse. If the return is a NSString, this gets directly returned as the content of the http response. If the response is a NSDictionary, then the view templating system picks up the dictionary and provides the access to the dictionary using the templating engine. If the returned object is an instance of WebResponse (or subclass), this gets directly returned to the server. Templates also follow a standard method of nomenclature. The template file's name should be a concation of the controller and method name. This behavior can be over-ridded by using web controller methods to set a alternate template name.

**Views**
Froth provides a simple templating engine, where when the object returned from a web controller method request is not a string or WebResponse, is provided to the template and accessible using familiar kvo access. Views are not limited to templates. For returning xml or json or other custom responses, the user can directly return the string or use a WebResponse object.

**WebApplication**
Each web application has an instance of WebApplication (or subclass), that provides the central control over web requests and response handling as well as integration with templating and views.

**Example**
For a blog application that is accessible at http://example.com/path/to/webapp/blog, the blog controller should be titled WABlogController.

_Defualt Request Mapping_

HTTP GET requests to _./blog_
get mapped to **-(id)index:(WebRequest_)req_ in WABlogController (if implemented)**

HTTP POST requests to _./blog_
get mapped to **-(id)create:(WebRequest_)req_**

HTTP PUT requests to _./blog/{somevalue}_
get mapped to **-(id)update:(WebRequest_)req_**

HTTP DELETE requests to _./blog/{somevalue}_
get mapped to **-(id)delete:(WebRequest_)req_**

These mappings are optional and can be over-ridded. For more information see [HttpRequestRouting](HttpRequestRouting.md)

For a custom method, a http request to _./blog/read
get mapped to_-(id)readAction:(WebRequest_)req

This allows for any number of actions to be implemented by simply formating the objc method name as_

` -(id)<pathname>Action:(WebRequest*)request; `

**Basic Example**

```
@implementation WABlogController

// GET ./blog/read/{index of artical as int}
- (id)readAction:(WebRequest*)req {
  if([req.firstParam intValue] = 0]) {
    return @"My first blog post";
  }
  return [WebResponse notFoundResponse];
}

// GET ./blog
- (id)index:(WebRequest*)req {
  return [WebResponse redirectWithURL:@"http://google.ca"];
}

@end
```

Web applications have a single WebApplication (or subclass) instance that handles requests and response processing as well as corro

# Build Product Details #

Each web application is built into a standard Cocoa style bundle with the prefix of .webApp. Like standard Cocoa application bundles, webApp bundles allow for the application to be self contained and easily distributed and launched. webApps bundles contain application specific css/js/and img content, as well as any other static content needed for the execution of the webApp. Shared resources are also possible by defining a global shared resource folder for the web app.

Most of the configuration details for a webApp goes into it's Info.plist dictionary file. This information includes deployment information, host information as well as other needed runtime details. Other immutable application settings can either go in the Info.plist file or another plist (Ie DataSources.plist for Model db access info)

**Bundle File Structure**

```
TheWebApp.webApp
    /Contents
        /{Platform}
            /TheWebApp
        /Resources
            /(view templates go here)
    /static
        /css, js, img, ...
```

The static folder is specially treated by the server. For amazon/lighttpd deployments, the static folder does not get handled by the webapplication, rather it is served directly from lighttpd.