Worker = require "../src/worker"

class Reverse
  run: (data, callback) ->
    callback null, data.split("").reverse().join("")

class Fail
  run: (data, callback) ->
    throw new Error("oh noes")

describe "Worker", ->
  beforeEach ->
    @socket = zmq.socket "req"
    @socket.bindSync "ipc:///tmp/bokeh-dealer"
    @worker = new Worker

  afterEach ->
    @worker.close()
    @socket.close()

  describe "#registerTask", ->
    it "should register a task", ->
      @worker.registerTask "reverse", Reverse
      expect(@worker.tasks.reverse).to.eql Reverse

  it "should send a completed response when a task is completed", (done) ->
    @worker.registerTask "reverse", Reverse
    @socket.send JSON.stringify(id: 123, request: "reverse", data: "hello")
    @socket.on "message", (payload) ->
      {id, response, data} = JSON.parse payload
      expect(id).to.eql 123
      expect(response).to.eql "completed"
      expect(data).to.eql "olleh"
      done()

  it "should send a failed response when a task failed", (done) ->
    @worker.registerTask "reverse", Fail
    @socket.send JSON.stringify(id: 123, request: "reverse", data: "hello")
    @socket.on "message", (payload) ->
      {id, response, data} = JSON.parse payload
      expect(id).to.eql 123
      expect(response).to.eql "failed"
      expect(data).to.eql "Error: oh noes"
      done()
