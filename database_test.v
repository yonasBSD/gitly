module main

fn test_sql_table_quotes_identifiers() {
	assert sql_table('Commit') == '"commit"'
	assert sql_table('weird"name') == '"weird""name"'
}

fn test_sql_literal_escapes_single_quotes() {
	assert sql_literal("bob's repo") == "'bob''s repo'"
}

fn test_sql_like_pattern_wraps_and_escapes_query() {
	assert sql_like_pattern("bob's") == "'%bob''s%'"
}
