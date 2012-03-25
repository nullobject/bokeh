should = require "should"
zmq    = require "zmq"
Worker = require "../src/worker"

socket = worker = null
options = dealer: {endpoint: "ipc:///tmp/dealer"}

class Reverse
  run: (data, callback) ->
    callback null, data.split("").reverse().join("")

class Fail
  run: (data, callback) ->
    throw new Error("oh noes")

describe "Worker", ->
  beforeEach ->
    socket = zmq.socket "req"
    socket.bindSync options.dealer.endpoint
    worker = new Worker options

  afterEach ->
    worker.close()
    socket.close()

  describe "#registerTask", ->
    it "should register a task", ->
      worker.registerTask "reverse", Reverse
      worker.tasks.reverse.should.eql Reverse

  it "should send a completed response when a task is completed", (done) ->
    worker.registerTask "reverse", Reverse
    socket.send JSON.stringify(id: 123, request: "reverse", data: "hello")
    socket.on "message", (payload) ->
      {id, response, data} = JSON.parse payload
      id.should.eql 123
      response.should.eql "completed"
      data.should.eql "olleh"
      done()

  it "should send a failed response when a task failed", (done) ->
    worker.registerTask "reverse", Fail
    socket.send JSON.stringify(id: 123, request: "reverse", data: "hello")
    socket.on "message", (payload) ->
      {id, response, data} = JSON.parse payload
      id.should.eql 123
      response.should.eql "failed"
      data.should.eql "Error: oh noes"
      done()
