###
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
###

module.exports = (grunt) ->

  # Project configuration.
  grunt.initConfig

    # Metadata.
    pkg: grunt.file.readJSON("package.json")
    #banner: "/*! <%= pkg.title || pkg.name %> - v<%= pkg.version %> - " + "<%= grunt.template.today(\"yyyy-mm-dd\") %>\n" + "<%= pkg.homepage ? \"* \" + pkg.homepage + \"\\n\" : \"\" %>" + "* Copyright (c) <%= grunt.template.today(\"yyyy\") %> <%= pkg.author.name %>;" + " Licensed <%= _.pluck(pkg.licenses, \"type\").join(\", \") %> */\n"

    coffeelint:
      client: ["client/**.coffee"]
      server: ["server/**.coffee"]
      options:
        arrow_spacing:
          level: "error"

        no_trailing_whitespace:
          level: "error"

        max_line_length:
          level: "ignore"

        space_operators:
          level: "warn"

    watch:
      gruntfile:
        files: "<%= jshint.gruntfile.src %>"
        tasks: ["jshint:gruntfile"]

      client:
        files: "<%= jshint.client.src %>"
        tasks: [
          "jshint:client"
          "qunit"
        ]

    browserify:
      client:
        src: "client/main.coffee"
        dest: "static/js/bundle.js"

      #TODO: should replace with workerify?
      mapworker:
        src: "client/mapworker.coffee"
        dest: "static/js/mapworker.js"

      options:
        #transform: ['coffeeify', 'workerify'],
        transform: [
          "coffeeify"
          "brfs"
        ]
        extension: ".coffee"
        debug: true
        ignoreGlobals: true

    mochaTest:
      client:
        options:
          #reporter: "spec"
          require: "coffee-script/register"

        src: ["test/**/*.coffee"]

  # These plugins provide necessary tasks.
  grunt.loadNpmTasks "grunt-contrib-watch"
  grunt.loadNpmTasks "grunt-browserify"
  grunt.loadNpmTasks "grunt-mocha-test"
  grunt.loadNpmTasks "grunt-coffeelint"

  # Default task.
  grunt.registerTask "test", ["mochaTest"]
  grunt.registerTask "lint", ["coffeelint"]
  grunt.registerTask "compile", ["browserify"]
  grunt.registerTask "default", [
    "lint"
    "test"
    "compile"
  ]
