module main

import veb

fn pick_plural_form(count int, forms []string) string {
	if forms.len == 1 {
		return forms[0]
	}
	if forms.len == 2 {
		return if count == 1 { forms[0] } else { forms[1] }
	}
	n := if count < 0 { -count } else { count }
	last_two := n % 100
	last := n % 10
	if last_two >= 11 && last_two <= 14 {
		return forms[2]
	}
	if last == 1 {
		return forms[0]
	}
	if last >= 2 && last <= 4 {
		return forms[1]
	}
	return forms[2]
}

fn format_count(count int, key string, lang Lang) veb.RawHtml {
	s := veb.tr(lang.str(), key).trim_space()
	forms := s.split('|')
	form := pick_plural_form(count, forms)
	return veb.RawHtml('<b>${count}</b> ${form}')
}

fn (mut app App) format_commits_count(repo Repo, branch_name string, lang Lang) veb.RawHtml {
	branch := app.find_repo_branch_by_name(repo.id, branch_name)
	nr_commits := app.get_repo_commit_count(repo.id, branch.id)

	return format_count(nr_commits, 'commits_count', lang)
}

fn (r &Repo) format_nr_branches(lang Lang) veb.RawHtml {
	return format_count(r.nr_branches, 'branches_count', lang)
}

fn (r &Repo) format_nr_tags(lang Lang) veb.RawHtml {
	return format_count(r.nr_tags, 'tags_count', lang)
}

fn (r &Repo) format_nr_open_prs(lang Lang) veb.RawHtml {
	return format_count(r.nr_open_prs, 'prs_count', lang)
}

fn (r &Repo) format_nr_open_issues(lang Lang) veb.RawHtml {
	return format_count(r.nr_open_issues, 'issues_count', lang)
}

fn (r &Repo) format_nr_contributors(lang Lang) veb.RawHtml {
	return format_count(r.nr_contributors, 'contributors_count', lang)
}

fn (r &Repo) format_nr_topics(lang Lang) veb.RawHtml {
	return format_count(r.nr_topics, 'topics_count', lang)
}

fn (r &Repo) format_nr_releases(lang Lang) veb.RawHtml {
	return format_count(r.nr_releases, 'releases_count', lang)
}
