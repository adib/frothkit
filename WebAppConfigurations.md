# Introduction #

Frothkit provides the ability to setup multiple deployment modes of a single webapp. Developers can have beta, staging or any other version of their web app running on different or the same server using Xcode's Build Configurations and a Deployments.plist file. The fmtool cli that is installed on the server uses the Deployments.plist configuration to provide configuration details to lighttpd. These details are essential for lighttpd to determine where static resources, as well as shared resources are located and mapped to uris.

## Details ##

Each deployment is configured using the same name as specified under the active target's configuration. The webapp will be deployed under a given configuration that is selected from "Project->Set Active Configuration" menu. Each configuration's build setting's should have a "FROTH\_HOST" key/value specifying the host or ip to deploy the webapp to, as well as a FROTH\_IDENTITY key/value that is the path to the local identity key used to securely connect to the remote instance via ssh, without needing to supply a password.

Corresponding to the build configurations should be a "Deployment.plist" file that is included with the "Copy Bundle Resources" build phase. This file provides information to the running web app instance, as well as fmtool, about the port, root and host information for a given instance. The plist has a root "Dictionary" node with key name "Modes" that includes the list of all deployment modes available for the webapp. Each child, is a subsequent dictionary with a key name corresponding to the build configuration name. This dictionary should have the following key/values.

  * Root - The root path for the webapp, for example if multiple web apps are sharing a single domain.
  * Port - A unique port number that the webapp will listen on. (for lighttpd)
  * Host - The domain name or regex string with multiple domains the webapp listens to.
  * Disabled - (Optional Boolean) Allows for disabling a web app.

Web app projects that are created using the "Web Application" template have most of these details already configured. All that needs to be set is the "FROTH\_HOST/FROTH\_IDENTITY" combination for the current active build configuration, as well as modifying the included Deployments.plist with domain and path information.