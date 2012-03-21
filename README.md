# Bokeh

A scalable background processing server based on [ZeroMQ](http://www.zeromq.org/).

Bokeh consists of three components: the client, broker and worker.

## Installation

You must have ZeroMQ installed:

    brew install zeromq

Then install using npm:

    npm install bokeh

## Usage

### Task

A task is a unit of work which is run by workers.

    class Sleeper
      run: (data, callback) ->
        setTimeout ->
          callback "hello world"
        , data.timeout

### Client

A client is a process (your application) which submits tasks to the broker and monitors their progress.

    bokeh = require "bokeh"
    handle = bokeh.getClient().submitTask "Sleeper", timeout: 1000
    handle.on "complete", (data) -> console.log data
    handle.on "error", (data) -> console.error data

### Broker

The broker is a process responsible for routing messages from clients, journaling them to a store and dealing them to workers.

    bokeh = require "bokeh"
    broker = new bokeh.Broker
      store:
        type: "riak"
        options:
          bucket: "tasks"
          host:   "wt1.spleenjs.org"
          port:   8098

### Worker

A worker is a process which receives tasks from a broker and runs them. Workers can be run on the same host as the broker, or scaled-out onto separarate hosts for more processing power.

    bokeh = require "bokeh"
    worker = new bokeh.Worker
    worker.registerTask "Sleeper", require("./tasks/sleeper")

## Running the tests

    cake test
