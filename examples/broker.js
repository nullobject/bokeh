const Broker = require('../src/Broker')

const broker = new Broker({
  log: {
    level: 'debug',
    path: __dirname + '/bokeh.log'
  },
  store: {
    type: 'memory'
  }
})
