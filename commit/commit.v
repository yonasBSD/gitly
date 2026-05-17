// Copyright (c) 2019-2021 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license that can be found in the LICENSE file.
module main

import time

struct Commit {
mut:
	id         int @[primary; sql: serial]
	author_id  int
	author     string
	hash       string @[unique: 'commit']
	created_at int
	repo_id    int @[unique: 'commit']
	branch_id  int @[unique: 'commit']
	message    string
}

fn (commit Commit) relative() string {
	return time.unix(commit.created_at).relative()
}

fn (commit Commit) short_hash() string {
	if commit.hash.len <= 7 {
		return commit.hash
	}
	return commit.hash[..7]
}

fn (mut app App) commit_exists(repo_id int, branch_id int, hash string) bool {
	count := sql app.db {
		select count from Commit where repo_id == repo_id && branch_id == branch_id && hash == hash
	} or { 0 }
	return count > 0
}

fn (mut app App) add_commit(repo_id int, branch_id int, last_hash string, author string, author_id int, message string, date int) ! {
	new_commit := Commit{
		author_id:  author_id
		author:     author
		hash:       last_hash
		created_at: date
		repo_id:    repo_id
		branch_id:  branch_id
		message:    message
	}

	sql app.db {
		insert new_commit into Commit
	}!
}

fn (mut app App) find_repo_commits_as_page(repo_id int, branch_id int, offset int) []Commit {
	return sql app.db {
		select from Commit where repo_id == repo_id && branch_id == branch_id order by created_at desc limit 35 offset offset
	} or { []Commit{} }
}

fn (mut app App) get_repo_commit_count(repo_id int, branch_id int) int {
	return sql app.db {
		select count from Commit where repo_id == repo_id && branch_id == branch_id
	} or { 0 }
}

fn (mut app App) find_repo_commit_by_hash(repo_id int, hash string) Commit {
	commits := sql app.db {
		select from Commit where repo_id == repo_id && hash == hash
	} or { []Commit{} }
	if commits.len == 1 {
		return commits[0]
	}
	return Commit{}
}

fn (mut app App) find_repo_last_commit(repo_id int, branch_id int) Commit {
	commits := sql app.db {
		select from Commit where repo_id == repo_id && branch_id == branch_id order by created_at desc limit 1
	} or { []Commit{} }

	if commits.len == 0 {
		return Commit{}
	}

	return commits.first()
}

fn (app App) find_repo_last_commit_time(repo_id int) int {
	commits := sql app.db {
		select from Commit where repo_id == repo_id order by created_at desc limit 1
	} or { return 0 }
	if commits.len == 0 {
		return 0
	}
	return commits[0].created_at
}

const activity_weeks = 12

fn (app App) get_repo_activity_buckets(repo_id int) []int {
	week_seconds := 7 * 24 * 3600
	now := int(time.now().unix())
	cutoff := now - activity_weeks * week_seconds
	commits := sql app.db {
		select from Commit where repo_id == repo_id && created_at >= cutoff
	} or { []Commit{} }
	mut buckets := []int{len: activity_weeks}
	for c in commits {
		idx := (c.created_at - cutoff) / week_seconds
		if idx >= 0 && idx < activity_weeks {
			buckets[idx]++
		}
	}
	return buckets
}

// get_user_daily_activity returns commit counts per day for the given user
// over the past `days` days. Index 0 is the oldest day, index `days-1` is today.
fn (app App) get_user_daily_activity(user_id int, days int) []int {
	day_seconds := 24 * 3600
	now := time.now()
	// Anchor to the start of today (local), so today is always the last bucket.
	today_start := i64(time.new(year: now.year, month: now.month, day: now.day).unix())
	cutoff := int(today_start) - (days - 1) * day_seconds
	commits := sql app.db {
		select from Commit where author_id == user_id && created_at >= cutoff
	} or { []Commit{} }
	mut buckets := []int{len: days}
	for c in commits {
		idx := (c.created_at - cutoff) / day_seconds
		if idx >= 0 && idx < days {
			buckets[idx]++
		}
	}
	return buckets
}
