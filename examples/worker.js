const Worker = require('bokeh').Worker

// This task reverses the given string, failing randomly.
function reverse (data, callback) {
  if (Math.random() > 0.9) {
    callback('oh noes!')
  } else {
    callback(null, data.split('').reverse().join(''))
  }
}

const worker = new Worker({ dealer: 'tcp://broker:6001' })
worker.registerTask('reverse', reverse)
