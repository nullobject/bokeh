const Client = require('bokeh').Client
const client = new Client({ router: 'tcp://broker:6000' })
const NUM_TASKS = 10

setInterval(() => submitTasks(NUM_TASKS), 10000)
submitTasks(NUM_TASKS)

function submitTasks (n) {
  for (let i = 0; i < n; i++) {
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
}
