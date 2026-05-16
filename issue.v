// Copyright (c) 2019-2021 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license that can be found in the LICENSE file.
module main

import time
import veb

struct Issue {
	id int @[primary; sql: serial]
mut:
	author_id      int
	repo_id        int
	is_pr          bool
	assigned       []int   @[skip]
	labels         []Label @[skip]
	comments_count int
	title          string
	text           string
	created_at     int
	status         IssueStatus @[skip]
	linked_issues  []int       @[skip]
	repo_author    string      @[skip]
	repo_name      string      @[skip]
}

enum IssueStatus {
	open   = 0
	closed = 1
}

struct Label {
	id int @[primary; sql: serial]
mut:
	repo_id int
	name    string
	color   string
}

struct IssueLabel {
	id int @[primary; sql: serial]
mut:
	issue_id int
	label_id int
}

fn (mut app App) add_issue(repo_id int, author_id int, title string, text string) ! {
	app.add_issue_returning_id(repo_id, author_id, title, text)!
}

fn (mut app App) add_issue_returning_id(repo_id int, author_id int, title string, text string) !int {
	issue := Issue{
		title:      title
		text:       text
		repo_id:    repo_id
		author_id:  author_id
		created_at: int(time.now().unix())
	}

	sql app.db {
		insert issue into Issue
	}!
	return db_last_insert_id(app.db)
}

fn (mut app App) find_or_create_label(repo_id int, name string, color string) !int {
	existing := sql app.db {
		select from Label where repo_id == repo_id && name == name limit 1
	} or { []Label{} }
	if existing.len > 0 {
		return existing[0].id
	}
	label := Label{
		repo_id: repo_id
		name:    name
		color:   color
	}
	sql app.db {
		insert label into Label
	}!
	return db_last_insert_id(app.db)
}

fn (mut app App) add_issue_label(issue_id int, label_id int) ! {
	existing := sql app.db {
		select from IssueLabel where issue_id == issue_id && label_id == label_id limit 1
	} or { []IssueLabel{} }
	if existing.len > 0 {
		return
	}
	link := IssueLabel{
		issue_id: issue_id
		label_id: label_id
	}
	sql app.db {
		insert link into IssueLabel
	}!
}

fn (app &App) get_issue_labels(issue_id int) []Label {
	links := sql app.db {
		select from IssueLabel where issue_id == issue_id
	} or { []IssueLabel{} }
	mut labels := []Label{cap: links.len}
	for link in links {
		label := sql app.db {
			select from Label where id == link.label_id limit 1
		} or { []Label{} }
		if label.len > 0 {
			labels << label[0]
		}
	}
	return labels
}

fn (mut app App) find_issue_by_id(issue_id int) ?Issue {
	issues := sql app.db {
		select from Issue where id == issue_id limit 1
	} or { []Issue{} }
	if issues.len == 0 {
		return none
	}
	return issues.first()
}

fn (mut app App) find_repo_issues_as_page(repo_id int, page int) []Issue {
	off := page * commits_per_page
	return sql app.db {
		select from Issue where repo_id == repo_id && is_pr == false limit 35 offset off
	} or { []Issue{} }
}

fn (mut app App) get_repo_issue_count(repo_id int) int {
	return sql app.db {
		select count from Issue where repo_id == repo_id
	} or { 0 }
}

fn (mut app App) find_user_issues(user_id int) []Issue {
	return sql app.db {
		select from Issue where author_id == user_id && is_pr == false
	} or { []Issue{} }
}

fn (mut app App) delete_repo_issues(repo_id int) ! {
	sql app.db {
		delete from Issue where repo_id == repo_id
	}!
}

fn (mut app App) increment_issue_comments(id int) ! {
	sql app.db {
		update Issue set comments_count = comments_count + 1 where id == id
	}!
}

fn (i &Issue) relative_time() string {
	return time.unix(i.created_at).relative()
}

fn html_escape_text(s string) string {
	return s.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;').replace('"', '&quot;')
}

// formatted_title HTML-escapes the issue title and converts `backtick`-quoted
// segments into <code> spans so titles like `unknown method or field: ` + "`db.pg.Row.val`" + `` render nicely.
fn (i &Issue) formatted_title() veb.RawHtml {
	parts := i.title.split('`')
	mut out := ''
	for idx, p in parts {
		if idx % 2 == 0 {
			out += html_escape_text(p)
		} else if idx == parts.len - 1 {
			// Unmatched trailing backtick: keep as literal.
			out += '`' + html_escape_text(p)
		} else {
			out += '<code>' + html_escape_text(p) + '</code>'
		}
	}
	return out
}
