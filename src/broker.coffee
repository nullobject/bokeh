async = require "async"
fs    = require "fs"
zmq   = require "zmq"
Log   = require "log"
Riak  = require "./store/riak"

# A broker passes reqests/responses between clients/workers.
module.exports = class Broker
  constructor: (@options) ->
    @_initLog @options.log
    @_initStore @options.store
    @_initSockets()
    @_bindRouter()
    @_bindDealer()
    @_submitTasks()

  _initLog: (options) ->
    level = options?.level or "debug"
    stream = if options?.path?
      fs.createWriteStream options.path, flags: "a"
    else
      process.stdout
    @log = new Log level, stream

  # TODO: Building the correct store.
  _initStore: (options) ->
    @store = new Riak options.options
    @queue = async.queue (task, callback) =>
      @store.write task.id, task, callback
    , options.maxConnections or 8

  _initSockets: ->
    @router = zmq.socket "router"
    @dealer = zmq.socket "dealer"

  _bindRouter: ->
    @router.on "message", @_routerRx

    @router.bind @options.router.endpoint, =>
      @log.info "Router listening on %s", @options.router.endpoint

  _bindDealer: ->
    @dealer.on "message", @_dealerRx

    @dealer.bind @options.dealer.endpoint, =>
      @log.info "Dealer listening on %s", @options.dealer.endpoint

  _routerRx: (envelopes..., payload) =>
    task = JSON.parse payload

    @queue.push task, (error) =>
      if error?
        @_routerTx envelopes, id: task.id, response: "failed", data: error
        @log.warning "Failed to write task: %s (%s)", task.id, error
      else
        @_dealerTx envelopes, payload
        @_routerTx envelopes, id: task.id, response: "submitted"
        @log.info "Task submitted: %s", task.id

  _dealerRx: (envelopes..., payload) =>
    task = JSON.parse payload

    @store.delete task.id, (error) =>
      if error?
        @log.info "Failed to delete task: %s (%s)", task.id, error
      else
        @_routerTx envelopes, payload
        @log.info "Task %s: %s (%s)", task.response, task.id, task.data

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
      async.forEachSeries ids, @_submitTask, (error) =>
        throw error if error?
        @log.info "Pending tasks flushed"

  _submitTask: (id, callback) =>
    @store.read id, (error, task) =>
      if error?
        callback error
      else
        @_dealerTx new Buffer(""), id: task.id, request: task.request, data: task.data
        callback null
