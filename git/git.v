module git

import os

pub struct Git {}

pub fn Git.exec(args []string) os.Result {
	mut git_args := ['git']
	git_args << args
	return os.exec(git_args)
}

pub fn Git.exec_in_dir(dir string, args []string) os.Result {
	mut git_args := ['-C', dir]
	git_args << args
	return Git.exec(git_args)
}

pub fn Git.exec_in_dir_command(dir string, command string) os.Result {
	return Git.exec_in_dir(dir, split_command(command))
}

pub fn Git.exec_shell(command string) os.Result {
	return os.exec(['/bin/sh', '-c', command])
}

pub fn Git.clone(url string, path string) os.Result {
	println('new clone url="${url}" path="${path}"')
	return os.exec(['git', 'clone', '--bare', url, path])
}

pub fn Git.show_file_blob(repo_dir string, branch string, file_path string) !string {
	result := Git.exec_in_dir(repo_dir, ['--no-pager', 'show', '${branch}:${file_path}'])
	if result.exit_code != 0 {
		return error(result.output)
	}
	return result.output
}

fn split_command(command string) []string {
	mut args := []string{}
	mut current := []u8{}
	mut quote := u8(0)
	mut escaped := false

	for ch in command.bytes() {
		if escaped {
			current << ch
			escaped = false
			continue
		}
		if ch == `\\` {
			escaped = true
			continue
		}
		if quote != 0 {
			if ch == quote {
				quote = 0
			} else {
				current << ch
			}
			continue
		}
		if ch == `"` || ch == `'` {
			quote = ch
			continue
		}
		if ch.is_space() {
			if current.len > 0 {
				args << current.bytestr()
				current.clear()
			}
			continue
		}
		current << ch
	}
	if current.len > 0 {
		args << current.bytestr()
	}
	return args
}
