zmq  = require "zmq"
Task = require "./task"

# A worker processes tasks.
module.exports = class Worker
  constructor: (@options) ->
    @tasks = {}
    @_connect()

  registerTask: (name, klass) ->
    @tasks[name] = klass

  _connect: ->
    @socket = zmq.socket "rep"
    @socket.on "message", @_message
    @socket.connect @options.dealer.endpoint
    console.log "Worker connected to %s", @options.dealer.endpoint

  _message: (payload) =>
    {id, request, data} = JSON.parse payload

    task = new @tasks[request]

    try
      console.log "Task started: %s", id

      task.wrappedRun data, (error, data) =>
        response = if error? then "failed" else "completed"
        console.log "Task %s: %s", response, id
        payload = JSON.stringify id: id, response: response, data: data
        @socket.send payload
    catch error
      payload = JSON.stringify id: id, response: "failed", data: error.toString()
      @socket.send payload
