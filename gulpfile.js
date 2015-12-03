var	gulp           = require('gulp'),
	nodemon        = require('gulp-nodemon'),
	concat         = require('gulp-concat'),
	uglify		= require('gulp-minify-css'),
	jade           = require('gulp-jade'),
	browserSync    = require('browser-sync').create(),
	sourcemaps     = require('gulp-sourcemaps'),
	sass           = require('gulp-sass'),
	// clean          = require('gulp-clean'),
	elm            = require('gulp-elm'),
	// inject         = require('gulp-inject'),
	runSequence    = require('run-sequence');

var paths = {
	compileDestination: "dist",
	server  : './server',
	home    : ['src/index.jade'],
	sass    : ['src/**/*.{sass,scss}'],
	elm     : "src/**/*.elm",
	elmMain : "src/Main.elm",
	copy    : "src/Summary/d3.js"
};

/*
 * S E R V E R
 */
var config = require("./ignore/settings");

gulp.task('serve', function(cb){
	var called = false;
	return nodemon({
		"script": 'server/bin/www',     // port 5000 by default
	    "watch": paths.server,
		"ext": "js",
		// "env": {'NODE_ENV' : "development"}
		"env": config
	})
	.on('start', function () {
		if (!called) {
	       called = true;
	       cb();
		}
  	})
	.on('restart', function () {
      console.log('restarted!');
  });
});

/*
 * H T M L / C S S
 */

// runs jade on index.jade
gulp.task('home', function() {
	return gulp.src(paths.home)
	.pipe(jade({pretty: true}))
	.pipe(gulp.dest(paths.compileDestination));
});

gulp.task('sass', function() {
	return gulp.src('src/styles.sass')
	.pipe(sass().on('error', sass.logError))
	.pipe(concat('styles.css'))
	.pipe(uglify())
	.pipe(gulp.dest(paths.compileDestination))
	.pipe(browserSync.stream()); 			// injects new styles without page reload!
});

gulp.task('copyjs', function() {
	gulp.src(paths.copy)
	.pipe(gulp.dest(paths.compileDestination));
});

gulp.task('compilation', ['home', 'sass', 'copyjs']);

/*
 * E L M
 */

gulp.task('elm-init', elm.init);

gulp.task('elm-compile', ['elm-init'], function() {
	 // By explicitly handling errors, we prevent Gulp crashing when compile fails
     function onErrorHandler(err) {
         console.log(err.message);
     }
     return gulp.src(paths.elmMain)             // "./src/Main.elm"
         .pipe(elm())
         .on('error', onErrorHandler)
         .pipe(gulp.dest(paths.compileDestination));
 });

/*
 * D E V E L O P M E N T
 */

 gulp.task('watch', ['serve'], function() {
 	browserSync.init({
 		proxy: 'localhost:5000',
 	});

	gulp.watch(paths.home, ['home']);
	gulp.watch(paths.sass, ['sass']);
	gulp.watch(paths.copy, ['copyjs']);
	gulp.watch(paths.elm, ['elm-compile']);
	gulp.watch(paths.compileDestination+"/*.{js,html}").on('change', browserSync.reload);
 });

/*
 * P R O D U C T I O N
 */

/*
 * A P I
 */
gulp.task('default', ['compilation', 'elm-compile', 'watch']);
