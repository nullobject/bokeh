_   = require "underscore"
zmq = require "zmq"

# A worker processes tasks.
module.exports = class Worker
  constructor: (@options) ->
    @tasks = {}
    @_connect()

  # Closes the connection to the broker.
  close: ->
    @socket.close()

  # Registers a task with the given name and class.
  registerTask: (name, klass) ->
    @tasks[name] = klass

  _connect: ->
    @socket = zmq.socket "rep"
    @socket.on "message", @_message
    @socket.connect @options.dealer.endpoint
    console.log "Worker connected to %s", @options.dealer.endpoint

  _message: (payload) =>
    {id, request, data} = JSON.parse payload

    task = new @tasks[request] this

    console.log "Task started: %s", id

    @_runTask task, data, (error, data) =>
      response = if error?
        console.log "Task failed: %s (%s)", id, error
        "failed"
      else
        console.log "Task completed: %s", id
        "completed"
      payload = JSON.stringify id: id, response: response, data: data
      @socket.send payload

  _runTask: (task, data, callback) ->
    try
      task.run data, callback
    catch error
      callback error.toString()
