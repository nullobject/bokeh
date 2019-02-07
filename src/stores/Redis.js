const redis = require('redis')

const Redis = function (options) {
  this.options = options
  this.client = redis.createClient(this.options.port, this.options.host)
}

Object.assign(Redis.prototype, {
  write (key, data, callback) {
    this.client.hset(this.options.bucket, key, data, callback)
  },

  read (key, callback) {
    this.client.hget(this.options.bucket, key, callback)
  },

  delete (key, callback) {
    this.client.hdel(this.options.bucket, key, callback)
  },

  keys (callback) {
    this.client.hkeys(this.options.bucket, callback)
  }
})

module.exports = Redis
