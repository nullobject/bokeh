riak = require "riak-js"

module.exports = class Riak
  constructor: (@options) ->
    @client = riak.getClient @options

  write: (key, data, callback) ->
    @client.save @options.bucket, key, data, (error) ->
      if not error?
        callback null, this
      else
        callback error

  read: (key, callback) ->
    @client.get @options.bucket, key, (error, data) ->
      if not error?
        callback null, data
      else
        callback error

  readAll: (callback) ->
    @client.getAll @options.bucket, (error, data) ->
      if not error?
        callback null, data.map (object) -> object.data
      else
        callback error

  delete: (key, callback) ->
    @client.remove @options.bucket, key, (error) ->
      if not error?
        callback null
      else
        callback error
