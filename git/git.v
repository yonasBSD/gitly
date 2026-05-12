module git

import os

pub struct Git {}

pub fn clone(url string, path string) os.Result {
	return Git.clone(url, path)
}

pub fn Git.clone(url string, path string) os.Result {
	println('new clone url="${url}" path="${path}"')
	return os.exec(['git', 'clone', '--bare', url, path])
}

pub fn (mut r Repo) clone(url string, path string) os.Result {
	return Git.clone(url, path)
}
