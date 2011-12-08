You can use this framework if you want your OS X app to interact directly with V8 and/or Node.js.

CoreNode is really a thin wrapper around V8.  You spawn a dedicated Node thread which starts V8 and initializes Node.js.  You are then able to dispatch method calls asynchronously to this thread.

This is a fork of the Node.js plugin system inside of [Kod](https://github.com/rsms/kod).  Numerous bugs have been fixed and there is added support for JS closures which are now captured and able to be invoked from within Objective-C land.

## Install:
1. Drag the Xcode project into your project.
2. Open the 'Build Phases' tab of your project and add the CoreNode framework as a direct dependancy of your project.
3. Add the CoreNode framework under 'Link Binary With Libraries'.
4. Add a new 'Copy Files' Build Phase.
5. Change the destination of the 'Copy Files' build phase to 'Frameworks' and add the CoreNode framework to this build phase.
6. Switch to the 'Build Settings' tab and edit the 'Header Search Paths' setting for your application target.  Add the directory 'CoreNode/lib/node' relative to your application directory.

You can view the project settings for the Example project if you run into problems.
