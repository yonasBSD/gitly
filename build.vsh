import net.http

static_root := if exists('static/static') && !exists('static/assets') {
	'static/static'
} else {
	'static'
}
path := '${static_root}/css/gitly.css'
if !exists(path) {
	ret := system('sassc ${static_root}/css/gitly.scss > ${path}')
	if ret != 0 {
		http.download_file('https://gitly.org/css/gitly.css', path)!
		println('No sassc detected on this system, gitly.css has been downloaded from gitly.org.')
	}
}

ret := system('v .')
if ret == 0 {
	println('Gitly has been successfully built, run it with ./gitly')
}
