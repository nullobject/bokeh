task "build", "Compile Coffeescript source to Javascript", ->
  {exec} = require "child_process"
  invoke "clean"
  exec "coffee -c -o lib src", (error) ->
    throw error if error?

task "clean", "Remove generated Javascript", ->
  {exec} = require "child_process"
  exec "rm -rf lib", (error) ->
    throw error if error?

task "test", "Run unit tests", ->
  reporter = require("nodeunit").reporters.default
  reporter.run ["test"]
