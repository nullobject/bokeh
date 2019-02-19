const Broker = require('bokeh').Broker

const broker = new Broker({
  router: 'tcp://0.0.0.0:6000',
  dealer: 'tcp://0.0.0.0:6001',
  log: {
    level: 'debug',
    path: __dirname + '/bokeh.log'
  },
  store: {
    type: 'memory'
  }
})
