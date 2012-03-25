zmq = require "zmq"

# A worker processes tasks.
module.exports = class Worker
  constructor: (@options={}) ->
    @tasks = {}
    @_connect()

  # Closes the connection to the broker.
  close: ->
    @socket.close()

  # Registers a task with the given name and class.
  registerTask: (name, klass) ->
    @tasks[name] = klass

  _connect: ->
    endpoint = @options.dealer or "ipc:///tmp/bokeh-dealer"
    @socket = zmq.socket "rep"
    @socket.on "message", @_message
    @socket.connect endpoint

  _message: (payload) =>
    task = JSON.parse payload
    @_runTask task, (error, data) =>
      payload = if error?
        JSON.stringify id: task.id, response: "failed", data: error.toString()
      else
        JSON.stringify id: task.id, response: "completed", data: data
      @socket.send payload

  _runTask: (task, callback) ->
    try
      Task = @tasks[task.request]
      throw new Error("Unknown task '#{task.request}'") unless Task?
      instance = new Task this
      instance.run task.data, callback
    catch error
      callback error
