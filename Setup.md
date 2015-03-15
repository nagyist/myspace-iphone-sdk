MySpace iPhone SDK source code contains 3 targets:

  * MySpaceSDK
  * Framework
  * MySpaceSDKTester


---


## MySpaceSDK ##

This is the main SDK lib target.  This lib also contains OAuth and JSON libraries.  You can include the source files from this target in your application, or you can build it separately and package the SDK as a static framework in another project.

#### External projects (included): ####
  * [json-framework](http://code.google.com/p/json-framework/)
  * [OAuthConsumer](http://code.google.com/p/oauthconsumer/wiki/UsingOAuthConsumer) (note: NSMutableURLRequest+Parameters.m was modified to allow non-urlencoded body data)

## Framework ##

This target constructs the framework bundle so that the library can easily be included in other projects as a static framework.

IMPORTANT: when including the framework bundle created by this target, you MUST change the "File Type" property of the framework from "wrapper.framework" to "wrapper.framework.static"

## MySpaceSDKTester ##

This target is a test application that consumes the SDK as a static framework.  This application demonstrates basic use of the core functionality of the SDK.