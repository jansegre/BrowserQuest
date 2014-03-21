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
      },
      client: {
        src: ['client/**.js'],
        options: {
          force: true
        }
      },
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
        src: 'client/main.js',
        dest: 'static/js/bundle.js',
        options: {
          debug: true,
          ignoreGlobals: true
        }
      },
      mapworker: {
        src: 'client/mapworker.js',
        dest: 'static/js/mapworker.js',
        options: {
          debug: true,
          ignoreGlobals: true
        }
      }
    },
    mochaTest: {
      client: {
        options: {
          reporter: 'spec'
        },
        src: ['client/test/**.js']
      }
    }
  });

  // These plugins provide necessary tasks.
  grunt.loadNpmTasks('grunt-contrib-jshint');
  grunt.loadNpmTasks('grunt-contrib-watch');
  grunt.loadNpmTasks('grunt-browserify');
  grunt.loadNpmTasks('grunt-mocha-test');

  // Default task.
  grunt.registerTask('test', ['mochaTest']);
  grunt.registerTask('default', ['jshint', 'test', 'browserify']);

};
// vim: et sw=2 ts=2 sts=2
