# Introduction #

The frothkit Xcode project includes a Documentation target that will build and automatically install an Xcode docset for froth's api docs. While the documentation is not complete, and unedited, it can be a valuable reference for frothkit.


# Details #

To build the docset/documentation doxygen is needed. The easiest way to get doxegen is from here.

http://www.stack.nl/~dimitri/doxygen/download.html

If you are useing a different doxygen installation, then you will need to modify the Documentation target's _DOXYGEN\_PATH_ build setting for the appropriate path to the doxygen binary.

Once that is done, all thats needed is to build the _Documentation_ target.