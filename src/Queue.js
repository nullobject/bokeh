const Queue = function (worker, concurrency) {
  this._process = this._process.bind(this)
  this.worker = worker
  this.concurrency = concurrency
  this.tasks = []
  this.workers = 0
}

Object.assign(Queue.prototype, {
  push (tasks, callback) {
    if (!(tasks instanceof Array)) { tasks = [tasks] }
    for (let task of tasks) {
      this.tasks.push({ data: task, callback })
      process.nextTick(this._process)
    }
  },

  _process () {
    if ((this.workers < this.concurrency) && (this.tasks.length > 0)) {
      const task = this.tasks.shift()
      this.workers += 1
      this.worker(task.data, () => {
        this.workers -= 1
        if (task.callback !== null) { task.callback.apply(task, arguments) }
        process.nextTick(this._process)
      })
    }
  }
})

module.exports = Queue
