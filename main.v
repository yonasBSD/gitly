import os
import veb
import config

enum Lang {
	en
	ru
}

const tr_menu_en = '<select id=select_lang><option value=en selected>English</option><option value=ru>Русский</option></select>'
const tr_menu_ru = '<select id=select_lang><option value=en>English</option><option value=ru selected>Русский</option></select>'

fn get_port(conf config.Config) int {
	// Priority: -p flag > GITLY_PORT env > config.json port > 8080
	for i, arg in os.args {
		if (arg == '-p' || arg == '--port') && i + 1 < os.args.len {
			return os.args[i + 1].int()
		}
	}
	env_port := os.getenv_opt('GITLY_PORT') or { '' }
	if env_port != '' {
		return env_port.int()
	}
	if conf.port > 0 {
		return conf.port
	}
	return 8080
}

fn main() {
	if os.args.contains('ci_run') {
		return
	}
	mut app := new_app()!

	app.use(handler: app.before_request)

	app.port = get_port(app.config)

	veb.run_at[App, Context](mut app,
		port:               app.port
		family:             .ip
		timeout_in_seconds: 5
	) or { panic(err) }
}

fn build_tr_menu(cur_lang Lang) string {
	return match cur_lang {
		.ru { tr_menu_ru }
		.en { tr_menu_en }
	}
}
