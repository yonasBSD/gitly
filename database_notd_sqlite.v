module main

import config
import db.pg
import os

type GitlyDb = pg.DB

fn connect_db(conf config.Config) !GitlyDb {
	if conninfo := first_env_opt(['GITLY_DB_CONNINFO', 'DATABASE_URL'], conf.pg.conninfo) {
		return GitlyDb(pg.connect_with_conninfo(conninfo)!)
	}
	return GitlyDb(pg.connect(
		host:     first_env(['GITLY_DB_HOST', 'PGHOST'], conf.pg.host)
		port:     first_int_env(['GITLY_DB_PORT', 'PGPORT'], conf.pg.port)
		dbname:   first_env(['GITLY_DB_NAME', 'PGDATABASE'], conf.pg.dbname)
		user:     first_env(['GITLY_DB_USER', 'PGUSER'], conf.pg.user)
		password: first_env(['GITLY_DB_PASSWORD', 'PGPASSWORD'], conf.pg.password)
	)!)
}

fn db_backend_name() string {
	return 'postgres'
}

fn db_exec_values(db &GitlyDb, query string) ![][]string {
	rows := db.exec_no_null(query)!
	mut values := [][]string{cap: rows.len}
	for row in rows {
		values << row.vals.clone()
	}
	return values
}

fn db_column_exists(db &GitlyDb, table_name string, column_name string) !bool {
	rows := db_exec_values(db,
		'select column_name from information_schema.columns where table_name = ${sql_literal(table_name.to_lower())} and column_name = ${sql_literal(column_name)}')!
	return rows.len > 0
}

fn db_bool_column_type() string {
	return 'BOOLEAN NOT NULL DEFAULT false'
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

fn first_env_opt(keys []string, fallback string) ?string {
	value := first_env(keys, fallback)
	if value == '' {
		return none
	}
	return value
}

fn first_int_env(keys []string, fallback int) int {
	for key in keys {
		value := os.getenv(key)
		if value != '' {
			return value.int()
		}
	}
	return fallback
}
