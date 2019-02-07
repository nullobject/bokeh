const zmq = require('zeromq')

const Worker = require('./Worker')

function reverse (data, callback) {
  callback(null, data.split('').reverse().join(''))
}

function fail (data, callback) {
  throw new Error('oh noes')
}

let socket, worker

describe('Worker', () => {
  beforeEach(() => {
    socket = zmq.socket('req')
    socket.bindSync('ipc:///tmp/bokeh-dealer')
    worker = new Worker()
  })

  afterEach(() => {
    worker.close()
    socket.close()
  })

  describe('#registerTask', () =>
    it('should register a task', () => {
      worker.registerTask('reverse', reverse)
      expect(worker.tasks.reverse).toBe(reverse)
    })
  )

  it('should send a completed response when a task is completed', done => {
    worker.registerTask('reverse', reverse)
    socket.send(JSON.stringify({ id: 123, request: 'reverse', data: 'hello' }))
    socket.on('message', payload => {
      const { id, response, data } = JSON.parse(payload)
      expect(id).toBe(123)
      expect(response).toBe('completed')
      expect(data).toBe('olleh')
      done()
    })
  })

  it('should send a failed response when a task failed', done => {
    worker.registerTask('reverse', fail)
    socket.send(JSON.stringify({ id: 123, request: 'reverse', data: 'hello' }))
    socket.on('message', payload => {
      const { id, response, data } = JSON.parse(payload)
      expect(id).toBe(123)
      expect(response).toBe('failed')
      expect(data).toBe('Error: oh noes')
      done()
    })
  })
})
