module main

import veb

fn get_declension_form(count int, first_form string, second_form string) string {
	if count == 1 {
		return '<b>${count}</b> ${first_form}'
	}

	return '<b>${count}</b> ${second_form}'
}

fn (mut app App) format_commits_count(repo Repo, branch_name string) veb.RawHtml {
	branch := app.find_repo_branch_by_name(repo.id, branch_name)
	nr_commits := app.get_repo_commit_count(repo.id, branch.id)

	return get_declension_form(nr_commits, 'commit', 'commits')
}

fn (r &Repo) format_nr_branches() veb.RawHtml {
	return get_declension_form(r.nr_branches, 'branch', 'branches')
}

fn (r &Repo) format_nr_tags() veb.RawHtml {
	return get_declension_form(r.nr_tags, 'tag', 'tags')
}

fn (r &Repo) format_nr_open_prs() veb.RawHtml {
	return get_declension_form(r.nr_open_prs, 'pull request', 'pull requests')
}

fn (r &Repo) format_nr_open_issues() veb.RawHtml {
	return get_declension_form(r.nr_open_issues, 'issue', 'issues')
}

fn (r &Repo) format_nr_contributors() veb.RawHtml {
	return get_declension_form(r.nr_contributors, 'contributor', 'contributors')
}

fn (r &Repo) format_nr_topics() veb.RawHtml {
	return get_declension_form(r.nr_topics, 'Discussion', 'discussions')
}

fn (r &Repo) format_nr_releases() veb.RawHtml {
	return get_declension_form(r.nr_releases, 'release', 'releases')
}
