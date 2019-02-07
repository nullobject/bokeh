const uuid = require('uuid/v4')
const zmq = require('zeromq')
const events = require('events')

const Handle = function (id, callback) {
  this.id = id
  this.callback = callback
}

Handle.prototype = Object.create(events.EventEmitter.prototype)

/**
 * A client submits tasks to a broker.
 */
const Client = function (options = {}) {
  this._message = this._message.bind(this)
  this.options = options
  this.handles = {}
  this._connect()
}

Object.assign(Client.prototype, {
  /**
   * Closes the connection to the broker.
   */
  close () { this.socket.close() },

  /**
   * Submits a task with the given name and data.
   */
  submitTask (name, data, callback) {
    const handle = this._addHandle(uuid(), callback)
    const payload = JSON.stringify({ id: handle.id, request: name, data })
    this.socket.send([Buffer.alloc(0), payload])
    return handle
  },

  _connect () {
    const endpoint = this.options.router || 'ipc:///tmp/bokeh-router'
    this.socket = zmq.socket('dealer')
    this.socket.on('message', this._message)
    this.socket.connect(endpoint)
  },

  _message (...args) {
    const adjustedLength = Math.max(args.length, 1)
    const payload = args[adjustedLength - 1]
    const task = JSON.parse(payload)

    switch (task.response) {
      case 'submitted':
        this._submitted(task)
        break
      case 'completed':
        this._completed(task)
        break
      case 'failed':
        this._failed(task)
        break
      default:
        throw new Error(`Unknown response '${task.response}'`)
    }
  },

  _submitted (task) {
    const handle = this._getHandle(task.id)
    handle.emit('submit')
  },

  _completed (task) {
    const handle = this._getHandle(task.id)
    if (typeof handle.callback === 'function') {
      handle.callback(null, task.data)
    }
    handle.emit('complete', task.data)
    this._removeHandle(handle)
  },

  _failed (task) {
    const handle = this._getHandle(task.id)
    if (typeof handle.callback === 'function') {
      handle.callback(task.data)
    }
    if (handle.listeners('error').length !== 0) { handle.emit('error', task.data) }
    this._removeHandle(handle)
  },

  _getHandle (id) { return this.handles[id] },

  _addHandle (id, callback) {
    const handle = new Handle(id, callback)
    this.handles[id] = handle
    return handle
  },

  _removeHandle (handle) {
    delete this.handles[handle.id]
  }
})

module.exports = Client
