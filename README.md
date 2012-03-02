# Bokeh

A scalable background processing server based on [ZeroMQ](http://www.zeromq.org/).

Bokeh consists of four components: the task, client, broker and worker.

## Installation

You must have ZeroMQ installed:

    brew install zeromq

Install with npm:

    npm install bokeh

## Usage

### Task

    bokeh = require "bokeh"
    class Sleeper extends bokeh.Task
      run: (data, callback) ->
        setTimeout callback, data.timeout

### Client

    bokeh = require "bokeh"
    handle = bokeh.getClient().submitTask "Sleeper", timeout: 1000

### Broker

    bokeh = require "bokeh"
    broker = new bokeh.Broker
      store:
        type: "riak"
        options:
          bucket: "tasks"
          host:   "wt1.spleenjs.org"
          port:   8098

### Worker

    bokeh = require "bokeh"
    worker = new bokeh.Worker
    worker.registerTask "Sleeper", require("./tasks/sleeper")

## Running the tests

    cake test
