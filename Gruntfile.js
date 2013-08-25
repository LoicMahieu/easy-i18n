'use strict';

module.exports = function (grunt) {
  // load all grunt tasks
  require('matchdep').filterDev('grunt-*').forEach(grunt.loadNpmTasks);

  grunt.initConfig({
    watch: {
      coffeelint: {
        files: 'lib/**/*.js',
        tasks: ['coffeelint', 'coffee']
      }
    },
    coffeelint: {
      options: {
        'max_line_length': {
          value: 100
        }
      },
      all: [
        'src/**/*.coffee'
      ]
    },
    coffee: {
      src: {
        expand: true,
        flatten: true,
        cwd: 'src',
        src: ['**/*.coffee'],
        dest: 'lib',
        ext: '.js'
      }
    },
    mochaTest: {
      test: {
        options: {
          reporter: 'list',
          //require: 'coverage/blanket'
        },
        src: ['test/**/*.js']
      },
      coverage: {
        options: {
          reporter: 'html-cov',
          // use the quiet flag to suppress the mocha console output
          quiet: true
        },
        src: ['test/**/*.js'],
        // specify a destination file to capture the mocha
        // output (the quiet option does not suppress this)
        dest: 'coverage.html'
      }
    },
  });

  grunt.registerTask('test', [
    'coffeelint',
    'mochaTest'
  ]);

  grunt.registerTask('compile', [
    'coffeelint',
    'coffee'
  ]);

  grunt.registerTask('default', [
    'jshint'
  ]);
};
