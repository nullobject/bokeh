Client = require "../src/client"

describe "Client", ->
  beforeEach ->
    @socket = zmq.socket "rep"
    @socket.bindSync "ipc:///tmp/bokeh-router"
    @client = new Client

  afterEach ->
    @client.close()
    @socket.close()

  describe "#submitTask", ->
    it "should emit a submit event when a task is submitted", (done) ->
      @socket.on "message", (payload) =>
        task = JSON.parse payload
        payload = JSON.stringify id: task.id, response: "submitted"
        @socket.send payload
      handle = @client.submitTask "reverse", "hello"
      handle.on "submit", ->
        done()

    it "should emit a complete event when a task is completed", (done) ->
      @socket.on "message", (payload) =>
        task = JSON.parse payload
        payload = JSON.stringify id: task.id, response: "completed", data: "elloh"
        @socket.send payload
      handle = @client.submitTask "reverse", "hello"
      handle.on "complete", (data) ->
        expect(data).to.eql "elloh"
        done()

    it "should callback when a task is completed", (done) ->
      @socket.on "message", (payload) =>
        task = JSON.parse payload
        payload = JSON.stringify id: task.id, response: "completed", data: "elloh"
        @socket.send payload
      @client.submitTask "reverse", "hello", (error, data) ->
        expect(error).to.not.exist
        expect(data).to.eql "elloh"
        done()

    it "should emit an error event when a task failed", (done) ->
      @socket.on "message", (payload) =>
        task = JSON.parse payload
        payload = JSON.stringify id: task.id, response: "failed", data: "lorem"
        @socket.send payload
      handle = @client.submitTask "reverse", "hello"
      handle.on "error", (data) ->
        expect(data).to.eql "lorem"
        done()

    it "should callback when a task failed", (done) ->
      @socket.on "message", (payload) =>
        task = JSON.parse payload
        payload = JSON.stringify id: task.id, response: "failed", data: "lorem"
        @socket.send payload
      @client.submitTask "reverse", "hello", (error, data) ->
        expect(error).to.eql "lorem"
        expect(data).to.not.exist
        done()
