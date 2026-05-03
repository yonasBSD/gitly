module main

fn sql_table(name string) string {
	return '"' + name.to_lower().replace('"', '""') + '"'
}

fn sql_literal(value string) string {
	return "'" + value.replace("'", "''") + "'"
}

fn sql_like_pattern(value string) string {
	return sql_literal('%' + value + '%')
}
