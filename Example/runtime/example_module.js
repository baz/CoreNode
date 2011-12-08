function ExampleModule() {
  this.firstMethod = function(callback) {
    callback(null, 'first argument from JS', 'second argument from JS', 'third argument from JS');
  };

  this.secondMethod = function(objcArg, callback) {
    console.log(objcArg);

    var test = function(arg) {
      console.log('Executing from inside Node.js: '+arg);
    };

    callback(null, test);
  };

  this.thirdMethod = function(viewController, callback) {
    viewController.callMe();
    viewController.callMe_secondString_('first arg string', 'second arg string');
    callback(null, null);
  };
}

module.exports = new ExampleModule();
