{exec} = require "child_process"

task "build", "Compile Coffeescript source to Javascript", ->
  invoke "clean"
  exec "coffee -c -o lib src", (error) ->
    throw error if error?

task "clean", "Remove generated Javascript", ->
  exec "rm -rf lib", (error) ->
    throw error if error?
