_            = require "underscore"
uuid         = require "node-uuid"
zmq          = require "zmq"
EventEmitter = require("events").EventEmitter

class Handle extends EventEmitter
  constructor: (@name, @data, @callback) ->
    @id = uuid()

# A client submits tasks to a broker.
module.exports = class Client
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
    console.log "Client connected to %s", @options.router.endpoint

  _message: (envelopes..., payload) =>
    {id, response, data} = JSON.parse payload
    handle = @_getHandle id

    switch response
      when "submitted"
        @_submitted handle
      when "completed"
        @_completed handle, data
      when "failed"
        @_failed handle, data
      else
        throw "Unknown response '#{response}'"

  _submitted: (handle) ->
    console.log "Task submitted: %s", handle.id
    if handle.callback?
      handle.callback null, handle
      handle.callback = undefined
    handle.emit "submit"

  _completed: (handle, data) ->
    console.log "Task completed: %s", handle.id
    handle.emit "complete", data
    @_removeHandle handle

  _failed: (handle, data) ->
    console.log "Task failed: %s", handle.id
    if handle.callback?
      handle.callback data, handle
      handle.callback = undefined
      handle.emit "error", data unless _(handle.listeners("error")).isEmpty()
    else
      handle.emit "error", data
    @_removeHandle handle

  _addHandle: (handle) ->
    @handles[handle.id] = handle

  _removeHandle: (handle) ->
    delete @handles[handle.id]

  _getHandle: (id) ->
    @handles[id]
