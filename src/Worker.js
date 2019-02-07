const zmq = require('zeromq')

/**
 * A worker processes tasks.
 */
const Worker = function (options = {}) {
  this._message = this._message.bind(this)
  this.options = options
  this.tasks = {}
  this._connect()
}

Object.assign(Worker.prototype, {
  /**
   * Closes the connection to the broker.
   */
  close () {
    this.socket.close()
  },

  /**
   * Registers a task with the given name and handler function.
   */
  registerTask (name, handler) {
    this.tasks[name] = handler
  },

  _connect () {
    const endpoint = this.options.dealer || 'ipc:///tmp/bokeh-dealer'
    this.socket = zmq.socket('rep')
    this.socket.on('message', this._message)
    this.socket.connect(endpoint)
  },

  _message (payload) {
    const task = JSON.parse(payload)
    this._runTask(task, (error, data) => {
      payload = (error !== null)
        ? JSON.stringify({ id: task.id, response: 'failed', data: error.toString() })
        : JSON.stringify({ id: task.id, response: 'completed', data })
      this.socket.send(payload)
    })
  },

  _runTask (task, callback) {
    try {
      const handler = this.tasks[task.request]
      if (typeof handler !== 'function') { throw new Error(`Unknown task handler for '${task.request}'`) }
      handler(task.data, callback)
    } catch (error) {
      callback(error)
    }
  }
})

module.exports = Worker
