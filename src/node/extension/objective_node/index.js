// Copyright (c) 2010-2011, Rasmus Andersson. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

var events = require('events');

// set the objective_node module to the object created by the global _objective_node
if (global._objective_node) {
  module.exports = exports = global._objective_node;
} else {
  // we are being run outside of Objective-Node
  exports.outsideOfObjectiveNode = true;
}

// inherit from EventEmitter
for (var k in events.EventEmitter.prototype) {
  exports.__proto__[k] = events.EventEmitter.prototype[k];
}
events.EventEmitter.call(exports);

// install last line of defence for exceptions to avoid Node killing the app
process.on('uncaughtException', global._objective_node.handleUncaughtException);

console.log('Node thread started ('+ process.version +')');
