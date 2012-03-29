bokeh = require "../lib"

# This task reverses the given string, failing randomly.
class Reverse
  run: (data, callback) ->
    if Math.random() > 0.9
      callback "oh noes!"
    else
      callback null, data.split("").reverse().join("")

worker = new bokeh.Worker
worker.registerTask "Reverse", Reverse
