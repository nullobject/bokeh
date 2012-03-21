task "build", "Compile Coffeescript source to Javascript.", ->
  {exec} = require "child_process"
  invoke "clean"
  exec "coffee -c -o lib src", (error) ->
    throw error if error?

task "clean", "Remove generated Javascript.", ->
  {exec} = require "child_process"
  exec "rm -rf lib", (error) ->
    throw error if error?

task "test", "Run unit tests.", ->
  {exec}  = require "child_process"
  {print} = require "util"
  glob    = require "glob"
  glob "test/**/*.coffee", (error, files) ->
    exec "node_modules/mocha/bin/mocha #{files.join(" ")}", (error, stdout, stderr) ->
      print stdout if stdout?
      print stderr if stderr?
