module git

fn test_get_branch_name_from_reference() {
	assert get_branch_name_from_reference('refs/heads/master') == 'master'
	assert get_branch_name_from_reference('refs/heads/main') == 'main'
	assert get_branch_name_from_reference('refs/heads/fix-110') == 'fix-110'
}

fn test_split_command_keeps_quoted_arguments() {
	assert split_command('--no-pager log main --pretty="%h %s"') == ['--no-pager', 'log', 'main',
		'--pretty=%h %s']
	assert split_command('archive v1.0 --format=zip --output="/tmp/release archive.zip"') == [
		'archive',
		'v1.0',
		'--format=zip',
		'--output=/tmp/release archive.zip',
	]
}
