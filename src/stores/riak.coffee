riak = require "riak-js"

module.exports = class Riak
  constructor: (@options) ->
    @client = riak.getClient @options

  write: (key, data, callback) ->
    @client.save @options.bucket, key, data, callback

  read: (key, callback) ->
    @client.get @options.bucket, key, callback

  delete: (key, callback) ->
    @client.remove @options.bucket, key, callback

  keys: (callback) ->
    results = []

    stream = @client.keys @options.bucket, keys: "stream", (error) ->
      if error?
        callback error
      else
        callback null, results

    stream.on "keys", (keys) -> results.push key for key in keys

    stream.start()
