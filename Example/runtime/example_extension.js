var coreNode = require('core_node');

function ExampleExtension() {
}

coreNode.inheritNativeModule('_example_extension', ExampleExtension);
var exampleExtension = new ExampleExtension();
module.exports = exampleExtension;
