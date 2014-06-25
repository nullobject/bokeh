bokeh = require "../src"

broker = new bokeh.Broker
  log:
    level: "debug"
    path:  __dirname + "/bokeh.log"
  store:
    type: "memory"
