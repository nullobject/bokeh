async = require "async"
fs    = require "fs"
zmq   = require "zmq"
Log   = require "log"
Queue = require "./queue"

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

  _initStore: (options) ->
    Store  = require "./stores/#{options.type}"
    @store = new Store options.options
    @queue = new Queue (task, callback) =>
      @store.write task.id, task, callback
    , options.maxConnections or 1

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
        @log.error "Failed to write task: %s (%s)", task.id, error
      else
        @_dealerTx envelopes, payload
        @_routerTx envelopes, id: task.id, response: "submitted"
        @log.info "Task submitted: %s", task.id

  _dealerRx: (envelopes..., payload) =>
    task = JSON.parse payload
    switch task.response
      when "completed"
        @log.info "Task completed: %s", task.id
      when "failed"
        @log.error "Task failed: %s (%s)", task.id, task.data
      else
        throw new Error("Unknown response '#{task.response}'")
    @store.delete task.id, (error) =>
      if error?
        @log.error "Failed to delete task: %s (%s)", task.id, error
      else
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
      async.forEachSeries ids, @_submitTask, (error) =>
        throw error if error?

  _submitTask: (id, callback) =>
    @store.read id, (error, task) =>
      if error?
        callback error
      else
        @_dealerTx new Buffer(""), task
        @log.info "Task submitted: %s", task.id
        callback null
