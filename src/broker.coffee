async = require "async"
zmq   = require "zmq"
Riak  = require "./store/riak"

# A broker passes reqests/responses between clients/workers.
module.exports = class Broker
  constructor: (@options) ->
    @store = new Riak @options.store.options

    @router = zmq.socket "router"
    @dealer = zmq.socket "dealer"

    @queue = async.queue (task, callback) =>
      @store.write task.id, task, callback
    , @options.store.maxConnections or 8

    @_bindRouter()
    @_bindDealer()
    @_submitTasks()

  _bindRouter: ->
    @router.on "message", @_routerRx

    @router.bind @options.router.endpoint, =>
      console.log "Router listening on %s", @options.router.endpoint

  _bindDealer: ->
    @dealer.on "message", @_dealerRx

    @dealer.bind @options.dealer.endpoint, =>
      console.log "Dealer listening on %s", @options.dealer.endpoint

  _routerRx: (envelopes..., payload) =>
    task = JSON.parse payload

    @queue.push task, (error) =>
      if error?
        @_routerTx envelopes, id: task.id, response: "failed", data: error
      else
        @_dealerTx envelopes, payload
        @_routerTx envelopes, id: task.id, response: "submitted"

  _dealerRx: (envelopes..., payload) =>
    task = JSON.parse payload
    @store.delete task.id, (error) =>
      @_routerTx envelopes, payload

  _routerTx: (envelopes, payload) ->
    unless payload instanceof Buffer
      payload = JSON.stringify payload
    @router.send [envelopes, payload]

  _dealerTx: (envelopes, payload) ->
    unless payload instanceof Buffer
      payload = JSON.stringify payload
    @dealer.send [envelopes, payload]

  _submitTasks: ->
    @store.keys (error, ids) =>
      throw error if error?
      async.forEachSeries ids, @_submitTask, (error) ->
        throw error if error?
        console.log "Pending tasks flushed"

  _submitTask: (id, callback) =>
    @store.read id, (error, task) =>
      if error?
        callback error
      else
        @_dealerTx new Buffer(""), id: task.id, request: task.request, data: task.data
        callback null
