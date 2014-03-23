/*global module:false*/
module.exports = function(grunt) {

  // Project configuration.
  grunt.initConfig({
    // Metadata.
    pkg: grunt.file.readJSON('package.json'),
    banner: '/*! <%= pkg.title || pkg.name %> - v<%= pkg.version %> - ' +
      '<%= grunt.template.today("yyyy-mm-dd") %>\n' +
      '<%= pkg.homepage ? "* " + pkg.homepage + "\\n" : "" %>' +
      '* Copyright (c) <%= grunt.template.today("yyyy") %> <%= pkg.author.name %>;' +
      ' Licensed <%= _.pluck(pkg.licenses, "type").join(", ") %> */\n',
    // Task configuration.
    jshint: {
      options: {
        curly: true,
        eqeqeq: true,
        immed: true,
        latedef: true,
        newcap: true,
        noarg: true,
        sub: true,
        undef: true,
        unused: true,
        boss: true,
        eqnull: true,
        browser: true,
        node: true
        //globals: {}
      },
      gruntfile: {
        src: 'Gruntfile.js'
      }
    },
    coffeelint: {
      client: ['client/**.coffee'],
      options: {
        arrow_spacing: {
          level: 'error'
        },
        no_trailing_whitespace: {
          level: 'error'
        },
        max_line_length: {
          level: 'ignore'
        },
        space_operators: {
          level: 'warn'
        },
      }
    },
    watch: {
      gruntfile: {
        files: '<%= jshint.gruntfile.src %>',
        tasks: ['jshint:gruntfile']
      },
      client: {
        files: '<%= jshint.client.src %>',
        tasks: ['jshint:client', 'qunit'],
      },
    },
    browserify: {
      client: {
        src: 'client/main.coffee',
        dest: 'static/js/bundle.js',
      },
      //TODO: should replace with workerify?
      mapworker: {
        src: 'client/mapworker.coffee',
        dest: 'static/js/mapworker.js',
      },
      options: {
        //transform: ['coffeeify', 'workerify'],
        transform: ['coffeeify'],
        extension: '.coffee',
        debug: true,
        ignoreGlobals: true
      }
    },
    mochaTest: {
      client: {
        options: {
          reporter: 'spec',
          require: 'coffee-script/register'
        },
        src: ['client/test/**.coffee']
      }
    }
  });

  // These plugins provide necessary tasks.
  grunt.loadNpmTasks('grunt-contrib-jshint');
  grunt.loadNpmTasks('grunt-contrib-watch');
  grunt.loadNpmTasks('grunt-browserify');
  grunt.loadNpmTasks('grunt-mocha-test');
  grunt.loadNpmTasks('grunt-coffeelint');

  // Default task.
  grunt.registerTask('test', ['mochaTest']);
  grunt.registerTask('lint', ['jshint', 'coffeelint']);
  grunt.registerTask('compile', ['browserify']);
  grunt.registerTask('default', ['lint', 'test', 'compile']);

};
// vim: et sw=2 ts=2 sts=2
