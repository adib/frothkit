Froth is a Objective-C web application framework that brings the power and simplicity of Cocoa development to the web.

[Official Site](http://www.frothkit.org)

While froth web apps are technically deployable on many different platforms using [Cocotron](http://www.cocotron.org), currently our focus has been on the [Amazon EC2](http://aws.amazon.com/ec2/) cloud.

**Benefits of Froth**
  * Uses the tools and language Mac and iPhone developers have come to know and love.
  * Reuse existing objc/c code from desktop applications.
  * Simple view templating support.
  * Very fast and scalable.
  * Affordable hosting on Amazon EC2 Cloud.
  * Multiple builds and deployments using standard Xcode deployments.


**Simple Example**

```
@interface WAHelloController : WebActiveController {
}

// http://myexample.com/hello
- (id)helloAction:(WebRequest*)req;

// http://example.com/goodbye
- (id)goodbyeAction:(WebRequest*)req;

@end


@implementation WAHelloController

- (id)helloAction:(WebRequest*)req {
	return @"Hello World";
}

- (id)goodbyeAction:(WebRequest*)req {
	return @"Goodbye";
}

@end
```

**Some Docs**

[Background Information](WebAppAnatomy.md)

<a href='http://www.youtube.com/watch?feature=player_embedded&v=G-XmqOOBnWI' target='_blank'><img src='http://img.youtube.com/vi/G-XmqOOBnWI/0.jpg' width='425' height=344 /></a>

_FrothKit is sponsored by [Thinking Code Software Inc.](http://thinkingcode.ca)_