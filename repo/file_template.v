module main

import veb
import strings

fn (f File) format_commit_message() veb.RawHtml {
	msg := f.last_msg
	if msg.index_u8(`#`) == -1 {
		return veb.RawHtml(msg)
	}
	mut b := strings.new_builder(msg.len + 32)
	mut i := 0
	for i < msg.len {
		if msg[i] == `#` && i + 1 < msg.len && msg[i + 1].is_digit() {
			start := i
			i += 2
			for i < msg.len && msg[i].is_digit() {
				i++
			}
			issue_id := msg[start..i]
			b.write_string('<a class="issue-id-anchor" href="#">')
			b.write_string(issue_id)
			b.write_string('</a>')
			continue
		}
		b.write_u8(msg[i])
		i++
	}
	return veb.RawHtml(b.str())
}
