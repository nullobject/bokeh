should   = require "should"
testCase = require("nodeunit").testCase
zmq      = require "zmq"
Client   = require "../src/client"

socket = client = null
options = router: {endpoint: "ipc:///tmp/router"}

module.exports = testCase
  setUp: (callback) ->
    socket = zmq.socket "rep"
    socket.bindSync options.router.endpoint
    client = new Client options
    callback()

  tearDown: (callback) ->
    client.close()
    socket.close()
    callback()

  "submit a task": (test) ->
    socket.on "message", (payload) ->
      task = JSON.parse payload
      payload = JSON.stringify id: task.id, response: "submitted"
      socket.send payload
    handle = client.submitTask "reverse", "hello"
    handle.on "submit", ->
      test.done()

  "submit a task with a callback": (test) ->
    socket.on "message", (payload) ->
      task = JSON.parse payload
      payload = JSON.stringify id: task.id, response: "submitted"
      socket.send payload
    client.submitTask "reverse", "hello", (error, handle) ->
      should.not.exist error
      handle.name.should.eql "reverse"
      handle.data.should.eql "hello"
      test.done()

  "submit a task and fail": (test) ->
    socket.on "message", (payload) ->
      task = JSON.parse payload
      payload = JSON.stringify id: task.id, response: "failed", data: "lorem"
      socket.send payload
    handle = client.submitTask "reverse", "hello"
    handle.on "error", (data) ->
      data.should.eql "lorem"
      test.done()

  "submit a task with a callback and fail": (test) ->
    socket.on "message", (payload) ->
      task = JSON.parse payload
      payload = JSON.stringify id: task.id, response: "failed", data: "lorem"
      socket.send payload
    client.submitTask "reverse", "hello", (error, handle) ->
      error.should.eql "lorem"
      handle.on "error", (data) ->
      test.done()

  "complete a task": (test) ->
    socket.on "message", (payload) ->
      task = JSON.parse payload
      payload = JSON.stringify id: task.id, response: "completed", data: "elloh"
      socket.send payload
    handle = client.submitTask "reverse", "hello"
    handle.on "complete", (data) ->
      data.should.eql "elloh"
      test.done()
