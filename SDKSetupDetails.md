# Introduction #

In order to make web application development as painless and fast as possible, froth depends on a specific resource directory structure for both the sdk and deployment. The installer will automatically create the sdk and deployment environment for you.

# Details #

The FrothSDK installer (as of dp2r47) uses Xcode's platform system. The froth framework, cross compiler and sdk is now installed at /Developer/Platforms/Froth.platform

The quickest way to get started is to use an sdk installer availible from http://frothkit.org.

# Deployment Paths #

**/var/froth/apps/{deploy-config}/{name}.webApp**

Web App bundle deployment location.

**/var/froth/shared/**

Public shared httpd folder for all applications installed on machine. This is accessible from http://{host}/shared

**/var/froth/data/**

Application specific file data.

For amazon amis. The /var/froth folder should be setup as a symbolic link to a mounted _Elastic Block Store_ to keep install webapps and application data persisted across ami reboots.

**/usr/froth/bin**

Contains froth workspace binaries and tools for managing applications.

**/usr/froth/lib**

Contains Froth, Foundation and other objc frameworks.