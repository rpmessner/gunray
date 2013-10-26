module.exports = (grunt) ->
  grunt.initConfig
    pkg: grunt.file.readJSON('package.json')
    coffee:
      compile:
        files:
          'dist/gunray.js': 'lib/gunray/gunray.coffee'
          'test/cases.js': ['test/helpers.coffee', 'test/cases/*.coffee']
      glob_to_multiple:
        expand: true,
        flatten: true,
        cwd: 'test/cases',
        src: ['*.coffee'],
        dest: 'test/build/cases/',
        ext: '.js'
    coffeelint:
      app: ['lib/**/*.coffee']
      tests:
        files:
          src: ['test/cases/*.coffee']
    qunit:
      files: ['index.html']
    watch:
      files: ['<%= coffeelint.tests.files.src %>', '<%= coffeelint.app %>']
      tasks: ['coffeelint', 'coffee', 'qunit']

  grunt.loadNpmTasks('grunt-contrib-coffee')
  grunt.loadNpmTasks('grunt-contrib-uglify')
  grunt.loadNpmTasks('grunt-coffeelint')
  grunt.loadNpmTasks('grunt-contrib-qunit')
  grunt.loadNpmTasks('grunt-contrib-watch')

  grunt.registerTask('default', ['coffeelint', 'coffee', 'qunit'])
