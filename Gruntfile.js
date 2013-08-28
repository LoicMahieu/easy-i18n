'use strict';

module.exports = function (grunt) {
  // load all grunt tasks
  require('matchdep').filterDev('grunt-*').forEach(grunt.loadNpmTasks);

  grunt.initConfig({
    watch: {
      coffeelint: {
        files: 'src/**/*.coffee',
        tasks: ['coffeelint:src', 'coffee:src']
      },
      test: {
        files: 'test/*.coffee',
        tasks: ['coffeelint:test', 'coffee:test', 'mochaTest']
      }
    },
    coffeelint: {
      options: {
        'max_line_length': {
          value: 100
        }
      },
      src: [
        'src/**/*.coffee'
      ],
      test: [
        'test/*.coffee'
      ]
    },
    coffee: {
      src: {
        expand: true,
        cwd: 'src',
        src: ['**/*.coffee'],
        dest: 'lib',
        ext: '.js'
      },
      test: {
        expand: true,
        cwd: 'test',
        src: ['**/*.coffee'],
        dest: 'test_lib',
        ext: '.js'
      }
    },
    clean: {
      src: ['lib'],
      test: ['test_lib'],
      coverage: ['coverage.html']
    },
    mochaTest: {
      test: {
        options: {
          reporter: 'list',
          require: 'blanket'
        },
        src: ['test_lib/**/*.js']
      },
      coverage: {
        options: {
          reporter: 'html-cov',
          // use the quiet flag to suppress the mocha console output
          quiet: true,
          // specify a destination file to capture the mocha
          // output (the quiet option does not suppress this)
          captureFile: 'coverage.html'
        },
        src: ['test_lib/**/*.js']
      }
    },
  });

  grunt.registerTask('test', [
    'compile',
    'mochaTest',
    'clean:test'
  ]);

  grunt.registerTask('compile', [
    'clean:src',
    'coffeelint:src',
    'coffee:src'
  ]);

  grunt.registerTask('default', [
    'test',
    'watch'
  ]);
};
