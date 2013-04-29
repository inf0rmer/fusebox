module.exports = (grunt) ->

  grunt.initConfig
    pkg: grunt.file.readJSON('package.json')

    rig:
      browser:
        src: ['src/<%= pkg.name %>.coffee']
        dest: 'dist/<%= pkg.name %>.coffee'
      amd:
        src: ['src/<%= pkg.name %>-amd.coffee']
        dest: 'dist/<%= pkg.name %>-amd.coffee'

    coffee:
      compile:
        options:
          sourceMap: true
          bare: true
        files:
          'dist/<%= pkg.name %>.js': 'dist/<%= pkg.name %>.coffee'
          'dist/<%= pkg.name %>-amd.js': 'dist/<%= pkg.name %>-amd.coffee'

    uglify:
      options:
        banner: '/**\n' +
              ' * <%= pkg.title %> v<%= pkg.version %>\n' +
              ' *\n' +
              ' * Copyright (c) <%= grunt.template.today("yyyy") %>' +
              '<%= pkg.author %>\n' +
              ' * Distributed under BSD License\n' +
              ' *\n' +
              ' * Documentation and full license available at:\n' +
              ' * <%= pkg.homepage %>\n' +
              ' *\n' +
              ' */\n'
        mangle:
          except: ['_', '$', 'fusebox']
      browser:
        files:
          'dist/<%= pkg.name %>.min.js': ['dist/<%= pkg.name %>.js']
      amd:
        files:
          'dist/<%= pkg.name %>-amd.min.js': ['dist/<%= pkg.name %>-amd.js']

    watch:
      files: '<%= coffeelint.files %>'
      tasks: ['default']

    coffeelint:
      files: ['Gruntfile.coffee', 'src/*.coffee']


  grunt.registerTask 'default', ['coffeelint']
  grunt.registerTask 'build', [
    'coffeelint',
    'rig',
    'coffee',
    'uglify'
  ]

  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-coffeelint'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-contrib-jasmine'
  grunt.loadNpmTasks 'grunt-rigger'
  grunt.loadNpmTasks 'grunt-contrib-coffee'