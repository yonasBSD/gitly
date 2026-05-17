// Copyright (c) 2019-2026 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license that can be found in the LICENSE file.
module main

import veb
import validation

struct DiscussionWithUser {
	item Discussion
	user User
}

struct DiscussionCommentWithUser {
	item DiscussionComment
	user User
}

@['/:username/:repo_name/discussions']
pub fn (mut app App) handle_get_repo_discussions(mut ctx Context, username string, repo_name string) veb.Result {
	repo := app.find_repo_by_name_and_username(repo_name, username) or { return ctx.not_found() }
	if !app.has_user_repo_read_access(ctx, ctx.user.id, repo.id) && !repo.is_public {
		return ctx.not_found()
	}
	discussions := app.list_repo_discussions(repo.id)
	mut rows := []DiscussionWithUser{}
	for d in discussions {
		u := app.get_user_by_id(d.author_id) or { continue }
		rows << DiscussionWithUser{
			item: d
			user: u
		}
	}
	return $veb.html('templates/discussions.html')
}

@['/:username/:repo_name/discussions/new']
pub fn (mut app App) new_discussion(mut ctx Context, username string, repo_name string) veb.Result {
	if !ctx.logged_in {
		return ctx.redirect_to_login()
	}
	repo := app.find_repo_by_name_and_username(repo_name, username) or { return ctx.not_found() }
	if !app.has_user_repo_read_access(ctx, ctx.user.id, repo.id) && !repo.is_public {
		return ctx.not_found()
	}
	return $veb.html('templates/new/discussion.html')
}

@['/:username/:repo_name/discussions'; post]
pub fn (mut app App) handle_create_discussion(mut ctx Context, username string, repo_name string) veb.Result {
	if !ctx.logged_in {
		return ctx.redirect_to_login()
	}
	repo := app.find_repo_by_name_and_username(repo_name, username) or { return ctx.not_found() }
	title := ctx.form['title']
	body := ctx.form['body']
	category := ctx.form['category']
	if validation.is_string_empty(title) {
		return ctx.redirect('/${username}/${repo_name}/discussions/new')
	}
	cat := if category in ['general', 'qa', 'announcement', 'idea'] { category } else { 'general' }
	id := app.add_discussion(repo.id, ctx.user.id, title, body, cat) or {
		ctx.error('Could not create discussion')
		return ctx.redirect('/${username}/${repo_name}/discussions/new')
	}
	return ctx.redirect('/${username}/${repo_name}/discussions/${id}')
}

@['/:username/:repo_name/discussions/:id']
pub fn (mut app App) view_discussion(mut ctx Context, username string, repo_name string, id string) veb.Result {
	repo := app.find_repo_by_name_and_username(repo_name, username) or { return ctx.not_found() }
	if !app.has_user_repo_read_access(ctx, ctx.user.id, repo.id) && !repo.is_public {
		return ctx.not_found()
	}
	discussion := app.find_discussion(id.int()) or { return ctx.not_found() }
	if discussion.repo_id != repo.id {
		return ctx.not_found()
	}
	author := app.get_user_by_id(discussion.author_id) or { return ctx.not_found() }
	raw_comments := app.get_discussion_comments(discussion.id)
	mut comments := []DiscussionCommentWithUser{}
	for c in raw_comments {
		u := app.get_user_by_id(c.author_id) or { continue }
		comments << DiscussionCommentWithUser{
			item: c
			user: u
		}
	}
	is_owner := ctx.logged_in
		&& (repo.user_id == ctx.user.id || discussion.author_id == ctx.user.id)
	return $veb.html('templates/discussion.html')
}

@['/:username/:repo_name/discussions/:id/comments'; post]
pub fn (mut app App) handle_add_discussion_comment(mut ctx Context, username string, repo_name string, id string) veb.Result {
	if !ctx.logged_in {
		return ctx.redirect_to_login()
	}
	repo := app.find_repo_by_name_and_username(repo_name, username) or { return ctx.not_found() }
	discussion := app.find_discussion(id.int()) or { return ctx.not_found() }
	if discussion.repo_id != repo.id || discussion.is_locked {
		return ctx.redirect('/${username}/${repo_name}/discussions/${id}')
	}
	text := ctx.form['text']
	if validation.is_string_empty(text) {
		return ctx.redirect('/${username}/${repo_name}/discussions/${id}')
	}
	app.add_discussion_comment(discussion.id, ctx.user.id, text) or {}
	return ctx.redirect('/${username}/${repo_name}/discussions/${id}')
}

@['/:username/:repo_name/discussions/:id/lock'; post]
pub fn (mut app App) handle_lock_discussion(mut ctx Context, username string, repo_name string, id string) veb.Result {
	if !ctx.logged_in {
		return ctx.redirect_to_login()
	}
	repo := app.find_repo_by_name_and_username(repo_name, username) or { return ctx.not_found() }
	discussion := app.find_discussion(id.int()) or { return ctx.not_found() }
	if discussion.repo_id != repo.id {
		return ctx.not_found()
	}
	if repo.user_id != ctx.user.id {
		return ctx.redirect('/${username}/${repo_name}/discussions/${id}')
	}
	app.set_discussion_lock(discussion.id, !discussion.is_locked) or {}
	return ctx.redirect('/${username}/${repo_name}/discussions/${id}')
}

@['/:username/:repo_name/discussions/:id/delete'; post]
pub fn (mut app App) handle_delete_discussion(mut ctx Context, username string, repo_name string, id string) veb.Result {
	if !ctx.logged_in {
		return ctx.redirect_to_login()
	}
	repo := app.find_repo_by_name_and_username(repo_name, username) or { return ctx.not_found() }
	discussion := app.find_discussion(id.int()) or { return ctx.not_found() }
	if discussion.repo_id != repo.id {
		return ctx.not_found()
	}
	if repo.user_id != ctx.user.id && discussion.author_id != ctx.user.id {
		return ctx.redirect('/${username}/${repo_name}/discussions/${id}')
	}
	app.delete_discussion(discussion.id) or {}
	return ctx.redirect('/${username}/${repo_name}/discussions')
}

@['/:username/:repo_name/discussions/:id/answer/:cid'; post]
pub fn (mut app App) handle_mark_answer(mut ctx Context, username string, repo_name string, id string, cid string) veb.Result {
	if !ctx.logged_in {
		return ctx.redirect_to_login()
	}
	repo := app.find_repo_by_name_and_username(repo_name, username) or { return ctx.not_found() }
	discussion := app.find_discussion(id.int()) or { return ctx.not_found() }
	if discussion.repo_id != repo.id {
		return ctx.not_found()
	}
	if discussion.author_id != ctx.user.id && repo.user_id != ctx.user.id {
		return ctx.redirect('/${username}/${repo_name}/discussions/${id}')
	}
	app.mark_discussion_answer(discussion.id, cid.int()) or {}
	return ctx.redirect('/${username}/${repo_name}/discussions/${id}')
}
