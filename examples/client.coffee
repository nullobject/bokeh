bokeh = require "../src"
client = new bokeh.Client

for i in [0...1000]
  handle = client.submitTask "Reverse", "hello world"

  handle.on "submit", ->
    console.log "Submitted: %s", @id

  handle.on "complete", (data) ->
    console.log "Completed: %s (%s)", @id, data

  handle.on "error", (error) ->
    console.error "Failed: %s (%s)", @id, error
