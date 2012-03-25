uuid         = require "node-uuid"
zmq          = require "zmq"
EventEmitter = require("events").EventEmitter

class Handle extends EventEmitter
  constructor: (@id) ->

# A client submits tasks to a broker.
module.exports = class Client
  constructor: (@options={}) ->
    @handles = {}
    @_connect()

  # Closes the connection to the broker.
  close: -> @socket.close()

  # Submits a task with the given name and data.
  #
  # Returns a handle to the task.
  submitTask: (name, data) ->
    handle = @_addHandle()
    payload = JSON.stringify id: handle.id, request: name, data: data
    @socket.send [new Buffer(""), payload]
    handle

  _connect: ->
    endpoint = @options.router or "ipc:///tmp/bokeh-router"
    @socket = zmq.socket "dealer"
    @socket.on "message", @_message
    @socket.connect endpoint

  _message: (envelopes..., payload) =>
    task = JSON.parse payload
    switch task.response
      when "submitted"
        @_submitted task
      when "completed"
        @_completed task
      when "failed"
        @_failed task
      else
        throw new Error("Unknown response '#{task.response}'")

  _submitted: (task) ->
    handle = @_getHandle task.id
    handle.emit "submit"

  _completed: (task) ->
    handle = @_getHandle task.id
    handle.emit "complete", task.data
    @_removeHandle handle

  _failed: (task) ->
    handle = @_getHandle task.id
    handle.emit "error", task.data unless handle.listeners("error").length is 0
    @_removeHandle handle

  _addHandle: ->
    handle = new Handle uuid()
    @handles[handle.id] = handle
    handle

  _removeHandle: (handle) ->
    delete @handles[handle.id]

  _getHandle: (id) -> @handles[id]
