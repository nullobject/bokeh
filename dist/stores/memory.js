// Generated by CoffeeScript 1.7.1
(function() {
  var Memory;

  module.exports = Memory = (function() {
    function Memory(options) {
      this.options = options;
      this.values = {};
    }

    Memory.prototype.write = function(key, data, callback) {
      this.values[key] = data;
      return callback(null, this);
    };

    Memory.prototype.read = function(key, callback) {
      return callback(null, this.values[key]);
    };

    Memory.prototype["delete"] = function(key, callback) {
      delete this.values[key];
      return callback(null);
    };

    Memory.prototype.keys = function(callback) {
      return callback(null, Object.keys(this.values));
    };

    return Memory;

  })();

}).call(this);
