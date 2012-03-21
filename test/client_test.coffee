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
    it "should submit a task", (done) ->
      socket.on "message", (payload) ->
        task = JSON.parse payload
        payload = JSON.stringify id: task.id, response: "submitted"
        socket.send payload
      handle = client.submitTask "reverse", "hello"
      handle.on "submit", ->
        done()

    it "should submit a task with a callback", (done) ->
      socket.on "message", (payload) ->
        task = JSON.parse payload
        payload = JSON.stringify id: task.id, response: "submitted"
        socket.send payload
      client.submitTask "reverse", "hello", (error, handle) ->
        should.not.exist error
        handle.name.should.eql "reverse"
        handle.data.should.eql "hello"
        done()

    it "should submit a task and fail", (done) ->
      socket.on "message", (payload) ->
        task = JSON.parse payload
        payload = JSON.stringify id: task.id, response: "failed", data: "lorem"
        socket.send payload
      handle = client.submitTask "reverse", "hello"
      handle.on "error", (data) ->
        data.should.eql "lorem"
        done()

    it "should submit a task with a callback and fail", (done) ->
      socket.on "message", (payload) ->
        task = JSON.parse payload
        payload = JSON.stringify id: task.id, response: "failed", data: "lorem"
        socket.send payload
      client.submitTask "reverse", "hello", (error, handle) ->
        error.should.eql "lorem"
        handle.on "error", (data) ->
          done()

    it "should complete a task", (done) ->
      socket.on "message", (payload) ->
        task = JSON.parse payload
        payload = JSON.stringify id: task.id, response: "completed", data: "elloh"
        socket.send payload
      handle = client.submitTask "reverse", "hello"
      handle.on "complete", (data) ->
        data.should.eql "elloh"
        done()
