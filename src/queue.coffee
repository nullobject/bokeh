module.exports = class Queue
  constructor: (@worker, @concurrency) ->
    @tasks   = []
    @workers = 0

  push: (tasks, callback) ->
    tasks = [tasks] unless tasks instanceof Array
    for task in tasks
      @tasks.push data: task, callback: callback
      process.nextTick @_process

  _process: =>
    if @workers < @concurrency and @tasks.length > 0
      task = @tasks.shift()
      @workers += 1
      @worker task.data, =>
        @workers -= 1
        task.callback.apply task, arguments if task.callback?
        process.nextTick @_process
