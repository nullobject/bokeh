module.exports = class Task
  constructor: (@worker) ->

  wrappedRun: (data, callback) ->
    try
      @run data, callback
    catch error
      callback error
