###
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
###

# return a function that prints colored prefixed lines
printer = (prefix, color) ->
  pre = (prefix + "> ")[color]
  (data) ->
    console.log(data.trimRight().split("\n").map((l) -> pre + l).join("\n"))

module.exports = (grunt) ->

  # Project configuration.
  grunt.initConfig

    # Metadata.
    pkg: grunt.file.readJSON("package.json")
    #banner: "/*! <%= pkg.title || pkg.name %> - v<%= pkg.version %> - " + "<%= grunt.template.today(\"yyyy-mm-dd\") %>\n" + "<%= pkg.homepage ? \"* \" + pkg.homepage + \"\\n\" : \"\" %>" + "* Copyright (c) <%= grunt.template.today(\"yyyy\") %> <%= pkg.author.name %>;" + " Licensed <%= _.pluck(pkg.licenses, \"type\").join(\", \") %> */\n"

    coffeelint:
      gruntfile: "Gruntfile.coffee"
      client: ["client/**.coffee"]
      server: ["server/**.coffee"]
      common: ["common/**.coffee"]
      test: ["test/**.coffee"]
      options:
        arrow_spacing:
          level: "error"

        no_trailing_whitespace:
          level: "error"

        max_line_length:
          level: "ignore"

        space_operators:
          level: "warn"

    mochaTest:
      client:
        options:
          #reporter: "spec"
          require: "coffee-script/register"
        src: ["test/**/*.coffee"]

    browserify:
      client:
        src: "client/main.coffee"
        dest: "static/js/bundle.js"

      #TODO: should replace with workerify?
      mapworker:
        src: "client/mapworker.coffee"
        dest: "static/js/mapworker.js"

      options:
        transform: [
          "coffeeify"
          "brfs"
          #"workerify"
        ]
        extension: ".coffee"
        debug: true
        ignoreGlobals: true

    shell:
      redis:
        command: "redis-server"
        options:
          async: true
          failOnError: true
          stdout: printer("redis", "blue")
          stderr: printer("redis", "red")

      server:
        command: "coffee server/main.coffee"
        options:
          async: true
          stdout: printer("server", "cyan")
          stderr: printer("server", "red")
          stopIfStarted: true

    watch:
      config:
        files: [
          "Gruntfile.coffee"
          "package.json"
        ]
        options:
          reload: true

      client:
        files: [
          "<%= coffeelint.client %>"
          "<%= coffeelint.common %>"
        ]
        #TODO: livereload maybe?
        tasks: ["browserify"]

      server:
        files: [
          "<%= coffeelint.server %>"
          "<%= coffeelint.common %>"
        ]
        tasks: ["shell:server"]
        options:
          spawn: false

  # These plugins provide necessary tasks.
  grunt.loadNpmTasks "grunt-contrib-watch"
  grunt.loadNpmTasks "grunt-browserify"
  grunt.loadNpmTasks "grunt-mocha-test"
  grunt.loadNpmTasks "grunt-coffeelint"
  grunt.loadNpmTasks "grunt-shell-spawn"

  # Default task.
  grunt.registerTask "test", ["mochaTest"]
  grunt.registerTask "lint", ["coffeelint"]
  grunt.registerTask "compile", ["browserify"]
  grunt.registerTask "run", [
    #TODO: option to disable running redis in development
    "shell:redis"
    "shell:server"
    "watch"
  ]
  grunt.registerTask "default", [
    "lint"
    "test"
    "compile"
    "run"
  ]
