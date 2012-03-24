# Bokeh

Bokeh (pronounced boh-kay) is a simple, fast and scalable task queue built on [Node.js](http://nodejs.org) and [ZeroMQ](http://zeromq.org). It allows you to offload tasks from your main application process and distribute them among a pool of workers. Workers can be running on the same host as your application, or scaled out onto other machines for greater processing power.

When you want a worker to run a task, just submit it to the broker using the client API. A task is simply any class in your application which responds to the `run` method.

Bokeh consists of three components:

1. The client library which your application uses to submit tasks to the broker.
2. The broker process which manages the pool of workers.
3. The worker processes which are responsible for running tasks.

## Installation

### ZeroMQ

The only prerequisite is that you have ZeroMQ installed.

**OS X**

Install ZeroMQ using brew:

    $ brew install zeromq

**Ubuntu 10.04 LTS**

Install ZeroMQ using [Chris Lea's PPA](https://launchpad.net/~chris-lea/+archive/zeromq):

    $ sudo add-apt-repository ppa:chris-lea/zeromq
    $ sudo apt-get update
    $ sudo apt-get install libzmq-dbg libzmq-dev libzmq1

### Bokeh

Install Bokeh using npm:

    $ npm install bokeh

## Overview

### Task

A task is a class which responds to the `run` method. A task is dealt to a worker and executed.

Once the task has been completed, you must call the callback with any data you want to pass back to your application.

    class Reverse
      run: (data, callback) ->
        callback null, data.split("").reverse().join("")

### Client

The client is used by your application to submit tasks to the broker and monitor their progress.

    bokeh = require "bokeh"
    handle = bokeh.getClient().submitTask "Reverse", timeout: 1000
    handle.on "complete", (data) -> console.log data
    handle.on "error", (data) -> console.error data

### Broker

The broker is responsible for routing messages from clients, journaling them to a data store and dealing them to workers.

    bokeh = require "bokeh"
    broker = new bokeh.Broker

Bokeh supports pluggable data stores, the following data stores are supported:

* In-memory
* Redis
* Riak

### Worker

A worker is a process which receives tasks from a broker and executes them. You must register all your task classes with the worker.

    bokeh = require "bokeh"
    worker = new bokeh.Worker
    worker.registerTask "Reverse", require("./tasks/reverse")
