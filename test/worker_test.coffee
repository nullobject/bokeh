should   = require "should"
testCase = require("nodeunit").testCase
zmq      = require "zmq"
Worker   = require "../src/worker"

socket = worker = null
options = dealer: {endpoint: "ipc:///tmp/dealer"}

class Reverse
  run: (data, callback) ->
    callback null, data.split("").reverse().join("")

module.exports = testCase
  setUp: (callback) ->
    socket = zmq.socket "req"
    socket.bindSync options.dealer.endpoint
    worker = new Worker options
    callback()

  tearDown: (callback) ->
    worker.close()
    socket.close()
    callback()

  "register a task": (test) ->
    worker.registerTask "reverse", Reverse
    worker.tasks.reverse.should.eql Reverse
    test.done()

  "receive a message": (test) ->
    worker.registerTask "reverse", Reverse
    socket.send JSON.stringify(id: 123, request: "reverse", data: "hello")
    socket.on "message", (payload) ->
      {id, response, data} = JSON.parse payload
      data.should.eql "olleh"
      test.done()
