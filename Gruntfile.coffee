module.exports = (grunt) ->
  grunt.initConfig
    pkg: grunt.file.readJSON('package.json')
    coffee:
      compile:
        files:
          'lib/gunray/gunray.js': 'lib/gunray/gunray.coffee'
    # concat:
    #   options:
    #     separator: ';'
    #   dist:
    #     src: ['lib/**/*.coffee']
    coffeelint:
      app: ['lib/**/*.coffee']
      tests:
        files:
          src: ['test/cases/*.coffee']
    qunit:
      files: ['test.html']
    watch:
      files: ['<%= coffeelint.files.src %>', '<%= coffeelint.app %>']
      tasks: ['coffeelint', 'qunit']
  grunt.loadNpmTasks('grunt-contrib-coffee')
  grunt.loadNpmTasks('grunt-contrib-uglify')
  grunt.loadNpmTasks('grunt-coffeelint')
  grunt.loadNpmTasks('grunt-contrib-qunit')
  grunt.loadNpmTasks('grunt-contrib-watch')
  # grunt.loadNpmTasks('grunt-contrib-concat')

  grunt.registerTask('test', ['coffeelint', 'qunit'])
  grunt.registerTask('default', ['coffeelint', 'qunit', 'concat', 'uglify'])
