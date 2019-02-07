const zmq = require('zeromq')

const Client = require('./Client')

let socket, client

describe('Client', () => {
  beforeEach(() => {
    socket = zmq.socket('rep')
    socket.bindSync('ipc:///tmp/bokeh-router')
    client = new Client()
  })

  afterEach(() => {
    client.close()
    socket.close()
  })

  describe('#submitTask', () => {
    it('should emit a submit event when a task is submitted', done => {
      socket.on('message', payload => {
        const task = JSON.parse(payload)
        payload = JSON.stringify({ id: task.id, response: 'submitted' })
        socket.send(payload)
      })
      const handle = client.submitTask('reverse', 'hello')
      handle.on('submit', () => done())
    })

    it('should emit a complete event when a task is completed', done => {
      socket.on('message', payload => {
        const task = JSON.parse(payload)
        payload = JSON.stringify({ id: task.id, response: 'completed', data: 'elloh' })
        socket.send(payload)
      })
      const handle = client.submitTask('reverse', 'hello')
      handle.on('complete', data => {
        expect(data).toBe('elloh')
        done()
      })
    })

    it('should callback when a task is completed', done => {
      socket.on('message', payload => {
        const task = JSON.parse(payload)
        payload = JSON.stringify({ id: task.id, response: 'completed', data: 'elloh' })
        socket.send(payload)
      })
      client.submitTask('reverse', 'hello', (error, data) => {
        expect(error).toBe(null)
        expect(data).toBe('elloh')
        done()
      })
    })

    it('should emit an error event when a task failed', done => {
      socket.on('message', payload => {
        const task = JSON.parse(payload)
        payload = JSON.stringify({ id: task.id, response: 'failed', data: 'lorem' })
        socket.send(payload)
      })
      const handle = client.submitTask('reverse', 'hello')
      handle.on('error', data => {
        expect(data).toBe('lorem')
        done()
      })
    })

    it('should callback when a task failed', done => {
      socket.on('message', payload => {
        const task = JSON.parse(payload)
        payload = JSON.stringify({ id: task.id, response: 'failed', data: 'lorem' })
        socket.send(payload)
      })
      client.submitTask('reverse', 'hello', (error, data) => {
        expect(error).toBe('lorem')
        expect(data).toBe(undefined)
        done()
      })
    })
  })
})
