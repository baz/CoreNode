// Entry point for Node.js runtime

var coreNode = require('core_node');
var exampleExtension = require('example_extension');
var exampleModule = require('example_module');
coreNode.registerObject('exampleModule', exampleModule);

var envVar = process.env['OBJC_ENV_VAR'];
console.log(envVar);

console.log(exampleExtension.sampleMethod());

exampleExtension.performNotification();