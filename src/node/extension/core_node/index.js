// Copyright (c) 2010-2011, Rasmus Andersson. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.
var events = require('events');

var coreNode = global._core_node;

coreNode.inheritNativeModule = function(moduleName, target) {
  var _bindingObject = coreNode.binding[moduleName];

  for (var i in events.EventEmitter.prototype) {
    _bindingObject.__proto__[i] = events.EventEmitter.prototype[i];
  }
  events.EventEmitter.call(_bindingObject);

  target.prototype = _bindingObject;
};

// Install last line of defence for exceptions to avoid Node killing the app
process.removeListener('uncaughtException', global._core_node.handleUncaughtException);
process.on('uncaughtException', global._core_node.handleUncaughtException);

coreNode._notifyNodeActive();

module.exports = coreNode;
