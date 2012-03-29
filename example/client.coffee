bokeh = require "../lib"
client = new bokeh.Client

for i in [0...1000]
  handle = client.submitTask "Reverse", "hello world"

  handle.on "submit", ->
    console.log "Submitted: %s", handle.id

  handle.on "complete", (data) ->
    console.log "Completed: %s (%s)", handle.id, data

  handle.on "error", (error) ->
    console.error "Failed: %s (%s)", handle.id, error
