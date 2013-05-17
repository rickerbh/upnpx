upnpx
=====

Clone of upnpx - Open Source Mac OS X / iOS Cocoa UPnP Stack

The original repository is hosted on Google Code - http://code.google.com/p/upnpx/

Submodules
----------
This project uses CocoaHTTPServer as a submodule. After cloning this repo, run

    git submodule update --recursive --init

and all should be good. You might also need to add Security.framework and CFNetwork.framework to your project, if they're not already there.