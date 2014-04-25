module.exports = (grunt) ->
  grunt.initConfig
    pkg: grunt.file.readJSON('package.json')
    browserify:
      cases:
        src: [
          'test/cases/property_test.coffee',
          'test/cases/object_test.coffee',
          'test/cases/collection_test.coffee',
          'test/cases/templates_test.coffee',
          'test/cases/router_test.coffee',
          'test/cases/component_test.coffee'
        ]
        dest: 'dist/cases.js'
        options:
          bundleOptions:
            debug: true
          alias: ['./lib/gunray/index.coffee:gunray']
          aliasMappings:
            cwd: 'lib'
            src: ['gunray/**/*.coffee']
          # watch: true
          # keepAlive: true
          transform: ['coffeeify-redux']
      # dist:
      #   src: 'lib/gunray.coffee'
      #   dest: 'dist/gunray.js'
      #   options:
      #     watch: true
      #     keepAlive: true
      #     transform: ['coffeeify']
    exorcise:
      files:
        src: ['dist/cases.js']
        dest: 'dist/cases.map'
    coffeelint:
      app: ['lib/**/*.coffee']
      tests:
        files:
          src: ['test/cases/*.coffee']
    qunit:
      options:
        phantomPath: '/usr/local/bin/phantomjs'
      all: ['index.html']
    watch:
      files: ['<%= coffeelint.tests.files.src %>', 'lib/gunray/**/*.coffee']
      tasks: ['coffeelint', 'browserify:cases', 'exorcise', 'qunit']

  grunt.loadNpmTasks('grunt-exorcise')
  grunt.loadNpmTasks('grunt-browserify')
  grunt.loadNpmTasks('grunt-contrib-uglify')
  grunt.loadNpmTasks('grunt-coffeelint')
  # grunt.loadNpmTasks('grunt-contrib-qunit')
  grunt.loadNpmTasks('grunt-croc-qunit')
  grunt.loadNpmTasks('grunt-contrib-watch')

  grunt.registerTask('default', ['coffeelint', 'browserify:cases', 'exorcise', 'qunit'])
