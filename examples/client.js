const Client = require('../src/Client')
const client = new Client()

for (let i = 0; i < 10; i++) {
  const handle = client.submitTask('reverse', 'hello world')

  handle.on('submit', function () {
    console.log('Submitted: %s', this.id)
  })

  handle.on('complete', function (data) {
    console.log('Completed: %s (%s)', this.id, data)
  })

  handle.on('error', function (error) {
    console.error('Failed: %s (%s)', this.id, error)
  })
}
