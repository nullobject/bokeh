redis = require "redis"

module.exports = class Redis
  constructor: (@options) ->
    @client = redis.createClient @options.port, @options.host

  write: (key, data, callback) ->
    @client.hset @options.bucket, key, data, callback

  read: (key, callback) ->
    @client.hget @options.bucket, key, callback

  delete: (key, callback) ->
    @client.hdel @options.bucket, key, callback

  keys: (callback) ->
    @client.hkeys @options.bucket, callback
