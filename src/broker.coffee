zmq  = require "zmq"
Riak = require "./store/riak"

# A broker passes reqests/responses between clients/workers.
module.exports = class Broker
  constructor: (@options) ->
    @store  = new Riak @options.store.options
    @router = zmq.socket "router"
    @dealer = zmq.socket "dealer"
    @_bindRouter()
    @_bindDealer()
    @_submitTasks()

  _bindRouter: ->
    @router.on "message", @_routerMessage

    @router.bind @options.router.endpoint, =>
      console.log "Router listening on %s", @options.router.endpoint

  _bindDealer: ->
    @dealer.on "message", @_dealerMessage

    @dealer.bind @options.dealer.endpoint, =>
      console.log "Dealer listening on %s", @options.dealer.endpoint

  _routerMessage: (envelopes..., payload) =>
    task = JSON.parse payload

    @store.write task.id, task, (error) =>
      if not error?
        @dealer.send [envelopes, payload]

        # Tell the client we've submitted the task.
        payload = JSON.stringify id: task.id, response: "submitted"
        @router.send [envelopes, payload]
      else
        # Tell the client shit blew up.
        payload = JSON.stringify id: task.id, response: "failed", data: error.toString()
        @router.send [envelopes, payload]

  _dealerMessage: (envelopes..., payload) =>
    task = JSON.parse payload

    @store.delete task.id, (error) =>
      @router.send [envelopes, payload]

  _submitTasks: ->
    @store.readAll (error, tasks) =>
      throw error if error?
      @_submitTask task for task in tasks

  _submitTask: (task) ->
    payload = JSON.stringify id: task.id, request: task.request, data: task.data
    @dealer.send [new Buffer(""), payload]
