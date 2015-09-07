gulp = require 'gulp'
glut = require 'glut'

coffee = require 'gulp-coffee'
coffeeAmdify = require 'glut-coffee-amdify'

glut gulp,
  tasks:
    coffee:
      runner: coffee
      src: 'src/**/*.coffee'
      dest: 'lib'
    components:
      runner: coffeeAmdify
      src: ['src/components/**/*.coffee']
      dest: 'public/components'
    client:
      runner: coffee
      src: 'src/public/**/*.coffee'
      dest: 'public'
    clientCopy:
      src: [
        'src/public/**/*.js'
        'src/public/**/*.css'
        'src/public/**/*.jpg'
        'src/public/**/*.woff'
        'src/public/**/*.ttf'
        'src/public/**/*.otf'
        'src/public/**/*.svg'
        'src/public/**/*.eot'
      ]
      dest: 'public'
