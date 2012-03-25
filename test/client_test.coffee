should = require "should"
zmq    = require "zmq"
Client = require "../src/client"

socket = client = null
options = router: {endpoint: "ipc:///tmp/router"}

describe "Client", ->
  beforeEach ->
    socket = zmq.socket "rep"
    socket.bindSync options.router.endpoint
    client = new Client options

  afterEach ->
    client.close()
    socket.close()

  describe "#submitTask", ->
    it "should emit a submit event when a task is submitted", (done) ->
      socket.on "message", (payload) ->
        task = JSON.parse payload
        payload = JSON.stringify id: task.id, response: "submitted"
        socket.send payload
      handle = client.submitTask "reverse", "hello"
      handle.on "submit", ->
        done()

    it "should emit an error event when a task failed", (done) ->
      socket.on "message", (payload) ->
        task = JSON.parse payload
        payload = JSON.stringify id: task.id, response: "failed", data: "lorem"
        socket.send payload
      handle = client.submitTask "reverse", "hello"
      handle.on "error", (data) ->
        data.should.eql "lorem"
        done()

    it "should emit a complete event when a task is completed", (done) ->
      socket.on "message", (payload) ->
        task = JSON.parse payload
        payload = JSON.stringify id: task.id, response: "completed", data: "elloh"
        socket.send payload
      handle = client.submitTask "reverse", "hello"
      handle.on "complete", (data) ->
        data.should.eql "elloh"
        done()
