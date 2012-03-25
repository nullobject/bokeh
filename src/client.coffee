uuid         = require "node-uuid"
zmq          = require "zmq"
EventEmitter = require("events").EventEmitter

class Handle extends EventEmitter
  constructor: (@name, @data, @callback) ->
    @id = uuid()

# A client submits tasks to a broker.
module.exports = class Client extends EventEmitter
  constructor: (@options) ->
    @handles = {}
    @_connect()

  # Closes the connection to the broker.
  close: ->
    @socket.close()

  # Submits a task with the given name and data.
  #
  # Returns a handle to the task.
  submitTask: (name, data, callback) ->
    handle = new Handle name, data, callback
    @_addHandle handle
    payload = JSON.stringify id: handle.id, request: name, data: data
    @socket.send [new Buffer(""), payload]
    handle

  _connect: ->
    @socket = zmq.socket "dealer"
    @socket.on "message", @_message
    @socket.connect @options.router.endpoint

  _message: (envelopes..., payload) =>
    task = JSON.parse payload
    handle = @_getHandle task.id
    switch task.response
      when "submitted"
        @_submitted handle
      when "completed"
        @_completed handle, task.data
      when "failed"
        @_failed handle, task.data
      else
        throw new Error("Unknown response '#{task.response}'")

  _submitted: (handle) ->
    if handle.callback?
      handle.callback null, handle
      handle.callback = undefined
    handle.emit "submit"
    @emit "submit", handle

  _completed: (handle, data) ->
    handle.emit "complete", data
    @emit "complete", handle, data
    @_removeHandle handle

  _failed: (handle, data) ->
    if handle.callback?
      handle.callback data, handle
      handle.callback = undefined
    handle.emit "error", data unless handle.listeners("error").length is 0
    @emit "error", handle, data unless @listeners("error").length is 0
    @_removeHandle handle

  _addHandle: (handle) ->
    @handles[handle.id] = handle

  _removeHandle: (handle) ->
    delete @handles[handle.id]

  _getHandle: (id) ->
    @handles[id]
