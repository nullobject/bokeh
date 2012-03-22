riak = require "riak-js"

module.exports = class Riak
  constructor: (@options) ->
    @client = riak.getClient @options

  write: (key, data, callback) ->
    @client.save @options.bucket, key, data, (error) ->
      if error?
        callback error
      else
        callback null, this

  read: (key, callback) ->
    @client.get @options.bucket, key, (error, data) ->
      if error?
        callback error
      else
        callback null, data

  keys: (callback) ->
    results = []

    stream = @client.keys @options.bucket, keys: "stream", (error) ->
      if error?
        callback error
      else
        callback null, results

    stream.on "keys", (keys) -> results.push key for key in keys

    stream.start()

  delete: (key, callback) ->
    @client.remove @options.bucket, key, (error) ->
      if error?
        callback error
      else
        callback null
