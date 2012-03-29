# Bokeh example

The example application comprises of a client, broker and worker processes. The client submits multiple tasks to the broker which then deals them to the pool of workers.

It is strongly recommended that you use [Foreman](https://github.com/ddollar/foreman) to run the example application.

Install Foreman using gem:

    $ gem install foreman

## Running the example

First, make sure you're in the examples directory:

    $ cd examples

To start the application with 1 worker:

    $ foreman start

To start the application with 4 workers:

    $ foreman start -c client=1,broker=1,worker=4
