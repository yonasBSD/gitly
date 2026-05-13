module main

import config
import db.sqlite
import os

type GitlyDb = sqlite.DB

fn connect_db(conf config.Config) !GitlyDb {
	path := first_env(['GITLY_SQLITE_PATH', 'GITLY_DB_PATH'], conf.sqlite.path)
	return GitlyDb(sqlite.connect(path)!)
}

fn db_backend_name() string {
	return 'sqlite'
}

fn db_exec_values(db &GitlyDb, query string) ![][]string {
	rows := db.exec(query)!
	mut values := [][]string{cap: rows.len}
	for row in rows {
		values << row.vals.clone()
	}
	return values
}

fn db_column_exists(db &GitlyDb, table_name string, column_name string) !bool {
	rows := db_exec_values(db, 'pragma table_info(${sql_table(table_name)})')!
	for row in rows {
		if row.len > 1 && row[1] == column_name {
			return true
		}
	}
	return false
}

fn db_bool_column_type() string {
	return 'INTEGER NOT NULL DEFAULT 0'
}

fn first_env(keys []string, fallback string) string {
	for key in keys {
		value := os.getenv(key)
		if value != '' {
			return value
		}
	}
	return fallback
}
