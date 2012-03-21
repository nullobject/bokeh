should = require "should"
zmq    = require "zmq"
Worker = require "../src/worker"

socket = worker = null
options = dealer: {endpoint: "ipc:///tmp/dealer"}

class Reverse
  run: (data, callback) ->
    callback null, data.split("").reverse().join("")

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

  it "should receive a message", (done) ->
    worker.registerTask "reverse", Reverse
    socket.send JSON.stringify(id: 123, request: "reverse", data: "hello")
    socket.on "message", (payload) ->
      {id, response, data} = JSON.parse payload
      data.should.eql "olleh"
      done()
