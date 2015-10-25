var	gulp           = require('gulp'),
	nodemon        = require('gulp-nodemon'),
	concat         = require('gulp-concat'),
	jade           = require('gulp-jade'),
	browserSync    = require('browser-sync').create(),
	sourcemaps     = require('gulp-sourcemaps'),
	sass           = require('gulp-sass'),
	clean          = require('gulp-clean'),
	elm            = require('gulp-elm'),
	inject         = require('gulp-inject');
var runSequence    = require('run-sequence');

var paths = {
	compileDestination: "dist",
	server  : './server',
	home    : ['src/index.jade'],
	scss    : ['src/**/*.scss'],
	elm     : "src/**/*.elm",
	elmMain     : "src/Main.elm"
};

/*
 * S E R V E R
 */
gulp.task('serve', function(cb){
	var called = false;
	return nodemon({
		"script": 'server/bin/www',     // port 5000 by default
	    "watch": paths.server,
		"ext": "js"
	})
	.on('start', function () {
		if (!called) {
	       called = true;
	       cb();
		}
  	})
	.on('restart', function () {
      console.log('restarted!')
    })
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
	return gulp.src(paths.scss)
	.pipe(sass().on('error', sass.logError))
	.pipe(concat('styles.css'))
	.pipe(gulp.dest(paths.compileDestination))
	.pipe(browserSync.stream()); 			// injects new styles without page reload!
});

gulp.task('compilation', ['home', 'sass']);

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
 })

/*
 * D E V E L O P M E N T
 */

 gulp.task('watch', ['serve'], function() {
 	browserSync.init({
 		proxy: 'localhost:5000',
 	});

	gulp.watch(paths.home, ['home']);
	gulp.watch(paths.scss, ['sass']);
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

/* ******

gulp.task('injectjs', ['home'], function() {
	var sources = gulp.src(injectScripts, {read: false, cwd: paths.compileDestination});
	// var sources = gulp.src(injectScripts, {read: false, cwd: paths.compileDestination});

	return gulp.src(paths.compileDestination+'/index.html')
		.pipe(inject(sources))
		.pipe(gulp.dest(paths.compileDestination));
});
var	gulp           = require('gulp'),
    elm            = require('gulp-elm'),
    sass           = require('gulp-sass'),
    browserSync    = require('browser-sync');

var paths = {
    elm : "./src/*.elm",
    main : "./src/Main.elm",
    rest : ['src/*.{html,js,png}'],
    sass: 'src/*.scss',
    dist : '../server/public/elm/'
}
paths.distWatch = [ paths.dist, "!"+paths.dist+"*.css" ]

gulp.task('copy', function() {
    return gulp.src(paths.rest)
        .pipe(gulp.dest(paths.dist));
});

gulp.task('sass', function() {
	return gulp.src(paths.sass)
	.pipe(sass().on('error', sass.logError))
	.pipe(gulp.dest(paths.dist))
	.pipe(browserSync.stream()); 			// injects new styles with page reload!
});

gulp.task('serve', function() {
	browserSync.init({
        proxy: "http://localhost:5000"
        // server: {
        //     baseDir: paths.dist
        // }
	});
});

gulp.task('watch', ['serve'], function() {
// gulp.task('watch', function() {
    gulp.watch(paths.elm, ['compile']);
    gulp.watch(paths.rest, ['copy']);
    gulp.watch(paths.sass, ['sass']);
    gulp.watch(paths.distWatch).on('change', browserSync.reload);
});

gulp.task('default', ['compile', 'copy', 'sass', 'watch']);
*/
