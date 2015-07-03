// Generated on 2014-06-15 using generator-webapp 0.4.9
'use strict';

module.exports = function (grunt) {

    // Load grunt tasks automatically
    require('load-grunt-tasks')(grunt);

    // Time how long tasks take. Can help when optimizing build times
    require('time-grunt')(grunt);

    // Configurable paths
    var config = {
        app: 'app',
        dist: 'dist',
        repo: 'git@github.com:pixeltailgames/gm-mediaplayer.git'
    };

    // Define the configuration for all the tasks
    grunt.initConfig({

        // Project settings
        config: config,

        // Watches files for changes and runs tasks based on the changed files
        watch: {
            bower: {
                files: ['bower.json'],
                tasks: ['bowerInstall']
            },
            js: {
                files: ['<%= config.app %>/scripts/{,*/}*.js'],
                tasks: ['jshint'],
                options: {
                    livereload: true
                }
            },
            gruntfile: {
                files: ['Gruntfile.js']
            },
            sass: {
                files: ['<%= config.app %>/styles/{,*/}*.{scss,sass}'],
                tasks: ['sass:server']
            },
            styles: {
                files: ['<%= config.app %>/styles/{,*/}*.css'],
                tasks: ['newer:copy:styles']
            },
            livereload: {
                options: {
                    livereload: '<%= connect.options.livereload %>'
                },
                files: [
                    '<%= config.app %>/{,*/}*.html',
                    '.tmp/styles/{,*/}*.css',
                    '<%= config.app %>/images/{,*/}*'
                ]
            }
        },

        // The actual grunt server settings
        connect: {
            options: {
                port: 80,
                open: true,
                livereload: 35729,
                // Change this to '0.0.0.0' to access the server from outside
                hostname: 'localhost'
            },
            livereload: {
                options: {
                    middleware: function(connect) {
                        return [
                            connect.static('.tmp'),
                            connect().use('/bower_components', connect.static('./bower_components')),
                            connect.static(config.app)
                        ];
                    }
                }
            },
            dist: {
                options: {
                    base: '<%= config.dist %>',
                    livereload: false
                }
            }
        },

        // Empties folders to start fresh
        clean: {
            dist: {
                files: [{
                    dot: true,
                    src: [
                        '.tmp',
                        '<%= config.dist %>/*',
                        '!<%= config.dist %>/.git*'
                    ]
                }]
            },
            server: '.tmp'
        },

        // Make sure code styles are up to par and there are no obvious mistakes
        jshint: {
            options: {
                jshintrc: '.jshintrc',
                reporter: require('jshint-stylish')
            },
            all: [
                'Gruntfile.js',
                '<%= config.app %>/scripts/{,*/}*.js',
                '!<%= config.app %>/scripts/vendor/*'
            ]
        },

        // Compiles Sass to CSS and generates necessary files if requested
        sass: {
            options: {
                loadPath: [
                    'bower_components'
                ]
            },
            dist: {
                files: [{
                    expand: true,
                    cwd: '<%= config.app %>/styles',
                    src: ['*.scss'],
                    dest: '.tmp/styles',
                    ext: '.css'
                }]
            },
            server: {
                files: [{
                    expand: true,
                    cwd: '<%= config.app %>/styles',
                    src: ['*.scss'],
                    dest: '.tmp/styles',
                    ext: '.css'
                }]
            }
        },

        // Automatically inject Bower components into the HTML file
        bowerInstall: {
            app: {
                src: ['<%= config.app %>/*.html'],
                exclude: ['bower_components/bootstrap-sass-official/vendor/assets/javascripts/bootstrap.js']
            },
            sass: {
                src: ['<%= config.app %>/styles/{,*/}*.{scss,sass}']
            }
        },

        // Renames files for browser caching purposes
        rev: {
            dist: {
                files: {
                    src: [
                        '<%= config.dist %>/scripts/{,*/}*.js',
                        '<%= config.dist %>/styles/{,*/}*.css',
                        '<%= config.dist %>/images/{,*/}*.*',
                        '<%= config.dist %>/styles/fonts/{,*/}*.*',
                        '<%= config.dist %>/*.{ico,png}'
                    ]
                }
            }
        },

        // Reads HTML for usemin blocks to enable smart builds that automatically
        // concat, minify and revision files. Creates configurations in memory so
        // additional tasks can operate on them
        useminPrepare: {
            options: {
                dest: '<%= config.dist %>'
            },
            html: '<%= config.app %>/*.html'
        },

        // Performs rewrites based on rev and the useminPrepare configuration
        usemin: {
            options: {
                assetsDirs: ['<%= config.dist %>', '<%= config.dist %>/images']
            },
            html: ['<%= config.dist %>/{,*/}*.html'],
            css: ['<%= config.dist %>/styles/{,*/}*.css']
        },

        htmlmin: {
            dist: {
                options: {
                    collapseBooleanAttributes: true,
                    collapseWhitespace: true,
                    removeAttributeQuotes: true,
                    removeCommentsFromCDATA: true,
                    removeEmptyAttributes: true,
                    removeOptionalTags: true,
                    removeRedundantAttributes: true,
                    useShortDoctype: true
                },
                files: [{
                    expand: true,
                    cwd: '<%= config.dist %>',
                    src: '{,*/}*.html',
                    dest: '<%= config.dist %>'
                }]
            }
        },

        // Copies remaining files to places other tasks can use
        copy: {
            dist: {
                files: [{
                    expand: true,
                    dot: true,
                    cwd: '<%= config.app %>',
                    dest: '<%= config.dist %>',
                    src: [
                        '*.{ico,png,txt}',
                        '.htaccess',
                        'images/{,*/}*.{gif,jpeg,jpg,png,webp}',
                        '{,*/}*.html',
                        'styles/fonts/{,*/}*.*',
                        'scripts/services/**/*.js'
                    ]
                }]
            },
            styles: {
                expand: true,
                dot: true,
                cwd: '<%= config.app %>/styles',
                dest: '.tmp/styles/',
                src: '{,*/}*.css'
            }
        },

        // Run some tasks in parallel to speed up build process
        concurrent: {
            server: [
                'sass:server',
                'copy:styles'
            ],
            dist: [
                'sass',
                'copy:styles'
            ]
        },

        // Push HTML content to gh-pages branch
        buildcontrol: {
            options: {
                dir: '<%= config.dist %>',
                commit: true,
                push: true,
                message: 'Built %sourceName% from commit %sourceCommit% on branch %sourceBranch%'
            },
            pages: {
                options: {
                    remote: '<%= config.repo %>',
                    branch: 'gh-pages'
                }
            }
        }
    });


    grunt.registerTask('serve', function (target) {
        if (target === 'dist') {
            return grunt.task.run(['build', 'connect:dist:keepalive']);
        }

        grunt.task.run([
            'clean:server',
            'concurrent:server',
            'connect:livereload',
            'watch'
        ]);
    });

    grunt.registerTask('server', function (target) {
        grunt.log.warn('The `server` task has been deprecated. Use `grunt serve` to start a server.');
        grunt.task.run([target ? ('serve:' + target) : 'serve']);
    });

    grunt.registerTask('build', [
        'clean:dist',
        'useminPrepare',
        'concurrent:dist',
        'concat',
        'cssmin',
        'uglify',
        'copy:dist',
        // 'rev',
        'usemin',
        'htmlmin'
    ]);

    grunt.registerTask('pages', [
        'build',
        'buildcontrol:pages'
    ]);

    grunt.registerTask('default', [
        'newer:jshint',
        'build'
    ]);
};
