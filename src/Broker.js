const async = require('async')
const zmq = require('zeromq')

const Memory = require('./stores/Memory')
const Queue = require('./Queue')
const Redis = require('./stores/Redis')

// A broker passes reqests/responses between clients/workers.
const Broker = function (options = {}) {
  this._routerRx = this._routerRx.bind(this)
  this._dealerRx = this._dealerRx.bind(this)
  this._submitTask = this._submitTask.bind(this)
  this.options = options
  this._initStore()
  this._initSockets()
  this._bindRouter()
  this._bindDealer()
  this._submitTasks()
}

Object.assign(Broker.prototype, {
  _initStore () {
    const type = this.options.store && this.options.store.type
    let Store

    if (type === 'redis') {
      Store = Redis
    } else {
      Store = Memory
    }

    this.store = new Store(this.options.store && this.options.store.options)
    this.queue = new Queue((task, callback) => {
      this.store.write(task.id, task, callback)
    }, (this.options.store && this.options.store.maxConnections) || 1)
  },

  _initSockets () {
    this.router = zmq.socket('router')
    this.dealer = zmq.socket('dealer')
  },

  _bindRouter () {
    const endpoint = this.options.router || 'ipc:///tmp/bokeh-router'
    this.router.on('message', this._routerRx)
    this.router.bind(endpoint, function () {
      console.log('Router listening on %s', endpoint)
    })
  },

  _bindDealer () {
    const endpoint = this.options.dealer || 'ipc:///tmp/bokeh-dealer'
    this.dealer.on('message', this._dealerRx)
    this.dealer.bind(endpoint, function () {
      console.log('Dealer listening on %s', endpoint)
    })
  },

  _routerRx (...args) {
    const adjustedLength = Math.max(args.length, 1)
    const envelopes = args.slice(0, adjustedLength - 1)
    const payload = args[adjustedLength - 1]
    const task = JSON.parse(payload)

    this.queue.push(task, error => {
      if (error) {
        this._routerTx(envelopes, { id: task.id, response: 'failed', data: error })
        console.error('Failed to write task: %s (%s)', task.id, error)
      } else {
        this._dealerTx(envelopes, payload)
        this._routerTx(envelopes, { id: task.id, response: 'submitted' })
        console.log('Task submitted: %s', task.id)
      }
    })
  },

  _routerTx (envelopes, payload) {
    if (!(payload instanceof Buffer)) {
      payload = JSON.stringify(payload)
    }
    this.router.send(envelopes.concat(payload))
  },

  _dealerRx (...args) {
    const adjustedLength = Math.max(args.length, 1)
    const envelopes = args.slice(0, adjustedLength - 1)
    const payload = args[adjustedLength - 1]
    const task = JSON.parse(payload)

    switch (task.response) {
      case 'completed':
        console.log('Task completed: %s', task.id)
        break
      case 'failed':
        console.error('Task failed: %s (%s)', task.id, task.data)
        break
      default:
        throw new Error(`Unknown response '${task.response}'`)
    }
    this.store.delete(task.id, error => {
      if (error) {
        console.error('Failed to delete task: %s (%s)', task.id, error)
      } else {
        this._routerTx(envelopes, payload)
      }
    })
  },

  _dealerTx (envelopes, payload) {
    if (!(payload instanceof Buffer)) {
      payload = JSON.stringify(payload)
    }
    this.dealer.send(envelopes.concat(payload))
  },

  _submitTasks () {
    this.store.keys((error, ids) => {
      if (error) { throw error }
      async.forEachSeries(ids, this._submitTask, error => {
        if (error) { throw error }
      })
    })
  },

  _submitTask (id, callback) {
    this.store.read(id, (error, task) => {
      if (error) {
        callback(error)
      } else {
        this._dealerTx([Buffer.alloc(0)], task)
        console.log('Task submitted: %s', task.id)
        callback(null)
      }
    })
  }
})

module.exports = Broker
