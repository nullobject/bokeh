module.exports = class Memory
  constructor: (@options) ->
    @values = {}

  write: (key, data, callback) ->
    @values[key] = data
    callback null, this

  read: (key, callback) ->
    callback null, @values[key]

  delete: (key, callback) ->
    delete @values[key]
    callback null

  keys: (callback) ->
    callback null, Object.keys @values
