//
// Entry point for the main Kod nodejs thread
//
var kod = require('kod');

// Require and thus initialize the text parser
//require('kod/textparser');

// install last line of defence for exceptions to avoid nodejs killing Kod.app
process.on('uncaughtException', global._kod.handleUncaughtException);

// TODO: alter behavior of process.exit

// add our built-in module path to the front of require.paths
require.paths.unshift(require.paths.pop());

// load any user bootstrap script. Note that we are guaranteed to have a correct
// HOME in the env (it's explicitly set by Kod just as nodejs start).
var userModule = null;
try { userModule = require(process.env.HOME + '/.kod'); } catch (e) {}


// ----------------------------------------------------------------------------
// Things below this line is only used for development and debugging and not
// really meant to be in this file

/*if (typeof gc === 'function') {
  // if we are running with --expose_gc, force collection at a steady interval.
  // Note: this is a serious performance killer and only used for debugging
  setInterval(gc, 10000);
}*/

// debug
var util = require('util');
console.log('main.js started in node '+process.version);
//console.log('kod -> '+util.inspect(kod));
//console.log('process.env -> '+util.inspect(process.env));
//console.log('require.paths -> '+util.inspect(require.paths));

// function which returns the arguments it received
kod.exposedFunctions.ping = function(callback) {
  if (callback) {
    var args = Array.prototype.slice.call(arguments);
    args[0] = null; // replace first argument (callback) with an null error
    callback.apply(this, args);
  }
}

// function which returns w/o arguments
kod.exposedFunctions.silentPing = function(callback) {
  if (callback)
    callback(null);
}

// example exposed function which can be called from Kod using the
// KNodeInvokeExposedJSFunction function.
kod.exposedFunctions.foo = function(callback) {
  console.log('external function "foo" called with %s', util.inspect(callback));
  if (callback) {
    callback(null, {"bar":[1,2,3.4,"mos"],"grek en":"hoppär"});
  }
}

// example of an event being emitted from ObjC land
kod.on('openDocument', function(document) {
  console.log('open document event emitted with: %s',document.mofo);
  //console.log('openDocument: '+ util.inspect(document, 0, 4));
//  console.log('openDocument: #'+document.identifier+' '+document.type+
//              ' '+(document.url || '*new*'));

  // example of registering for the "edit" event, emitted after each edit to
  // a document.
  /*document.on('edit', function(version, location, changeDelta) {
    console.log(this+':edit -> %j', {
      version:version, location:location, changeDelta:changeDelta});
    // if we are to manipulate the text, we need to compare versions since
    // these things happen concurrently. Here, we wrap a "p" character in < & >:
    if (document.version == version && changeDelta == 1) {
      var text = document.text;
      var changedChar = text.substr(location, 1);
      if (changedChar == "p") {
        document.text = text.substr(0,location)+'<'+changedChar+'>'+
                        text.substr(location+1);
        if (document.version != version+1) {
          console.log("another edit happened while we where running. "+
                      "The effect is undefined from our perspective.");
        }
      }
    }
  })*/
});

// example event listener for the "activateDocument" event, emitted when a
// document becomes selected (when the selection changes)
kod.on('activateDocument', function(document) {
  // Dump document -- includes things like the word dictionary. Massive output.
  //console.log('activateDocument: '+util.inspect(document, 0, 4));
  console.log('activateDocument: #'+document.identifier+' '+document.type+
              ' '+(document.url || '*new*'));

  // As document objects are persistent, we can add properties to it which will
  // survive as long as the document is open
  var timeNow = (new Date()).getTime();
  if (document.lastSeenByNode) {
    console.log('I saw this document '+
                ((timeNow - document.lastSeenByNode)/1000)+
                ' seconds ago');
  }
  document.lastSeenByNode = timeNow;

  // Replace the contents of the document:
  //document.text = "Text\nreplaced\nby main.js";
});

kod.on('closeDocument', function(document, identifier) {
  //console.log('closeDocument: ['+docId+'] '+ util.inspect(document, 0, 4));
  console.log('closeDocument: #'+identifier+' '+document.type+
              ' '+(document.url || '*new*'));
});

// dump kod.allDocuments every 10 sec
/*setInterval(function(){
  //console.log("kod.allDocuments -> "+util.inspect(kod.allDocuments));
  //kod.allDocuments[0].hasMetaRuler = true;
}, 10000);*/
