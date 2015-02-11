module.exports = (grunt) ->

  # load all grunt tasks
  require('load-grunt-tasks')(grunt)

  grunt.initConfig

    watch:
      src:
        files: [
          'src/*.coffee'
          'test/specs/*.coffee'
        ]
        tasks: ['browserify:test']
      gruntfile:
        files: ['Gruntfile.coffee']

    clean:
      tmp: '.tmp'
      lib: 'lib'

    coffee:
      lib:
        options:
          bare: true
        expand: true
        flatten: true
        cwd: 'src'
        src: ['*.coffee']
        dest: 'lib'
        ext: '.js'

    browserify:
      options:
        browserifyOptions:
          extensions: ['.coffee']
        transform: ['coffeeify']
        debug: true
      build:
        files:
          'jscheme.js' : [
            'src/jscheme.coffee'
          ]
      test:
        options:
          debug: false
        files:
          '.tmp/jscheme-test.js' : [
            'test/specs/*.coffee'
          ]

    mochaTest:
      test:
        options:
          reporter: 'dot'
          compilers: 'coffee-script/register'
          require: './test/node/mocha_test.js'
        src: [
          'test/specs/*.coffee'
        ]

    karma:
      unit:
        configFile: 'karma.conf.coffee'
      unit_once:
        configFile: 'karma.conf.coffee'
        browsers: ['PhantomJS']
        singleRun: true
      browsers:
        configFile: 'karma.conf.coffee'
        browsers: ['Chrome', 'Firefox', 'Safari']
      build:
        configFile: 'karma.conf.coffee'
        browsers: ['Chrome', 'Firefox', 'Safari']
        singleRun: true

    uglify:
      dist:
        files:
          'jscheme.min.js': [
            'jscheme.js'
          ]

    bump:
      options:
        files: ['package.json', 'bower.json', 'version.json']
        commitFiles: ['-a'], # '-a' for all files
        pushTo: 'origin'
        push: true

    shell:
      npm:
        command: 'npm publish'

    revision:
      options:
        property: 'git.revision'
        ref: 'HEAD'
        short: true

    replace:
      revision:
        options:
          patterns: [
            match: /\"revision\": ?\"[a-z0-9]+\"/
            replacement: '"revision": "<%= git.revision %>"'
          ]
        files:
          'version.json': ['version.json']


  # Tasks
  # -----

  grunt.registerTask('dev', [
    'watch'
  ])

  grunt.registerTask('test', [
    'clean:tmp'
    'browserify:test'
    'karma:unit'
  ])

  grunt.registerTask('node-test', [
    'mochaTest'
  ])

  grunt.registerTask('build', [
    'clean'
    'add-revision'
    'browserify:test'
    'karma:build'
    'mochaTest'
    'coffee:lib'
    'browserify:build'
    'uglify'
  ])

  grunt.registerTask('add-revision', [
    'revision'
    'replace:revision'
  ])

  # Release a new version
  # Only do this on the `master` branch.
  #
  # options:
  # release:patch
  # release:minor
  # release:major
  grunt.registerTask 'release', (type) ->
    type ?= 'patch'
    grunt.task.run('build')
    grunt.task.run('bump:' + type)
    grunt.task.run('shell:npm')


  grunt.registerTask('default', ['dev'])
