const Worker = require('../src/Worker')

// This task reverses the given string, failing randomly.
function reverse (data, callback) {
  if (Math.random() > 0.9) {
    callback('oh noes!')
  } else {
    callback(null, data.split('').reverse().join(''))
  }
}

const worker = new Worker()
worker.registerTask('reverse', reverse)
