const Memory = function (options) {
  this.options = options
  this.values = {}
}

Object.assign(Memory.prototype, {
  write (key, data, callback) {
    this.values[key] = data
    callback(null, this)
  },

  read (key, callback) {
    callback(null, this.values[key])
  },

  delete (key, callback) {
    delete this.values[key]
    callback(null)
  },

  keys (callback) {
    callback(null, Object.keys(this.values))
  }
})

module.exports = Memory
