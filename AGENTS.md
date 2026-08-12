# ruby-hello-world-app

Minimal Sinatra + Puma recipe on Zerops with a PostgreSQL-backed health endpoint and `zsc execOnce` migrations — baseline Ruby web recipe.

## Zerops service facts

- HTTP port: `8080`
- Siblings: `db` (PostgreSQL) — env: `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASS`, `DB_NAME`
- Runtime base: `ruby@3.4`

## Zerops dev

`setup: dev` idles on `zsc noop --silent`; the agent starts the dev server.

- Dev command: `bundle exec puma -p 8080 -b tcp://0.0.0.0` (or `bundle exec rerun -- puma -p 8080 -b tcp://0.0.0.0` for auto-reload — `rerun` is in the dev group)

**All platform operations (start/stop/status/logs of the dev server, deploy, env / scaling / storage / domains) go through the Zerops development workflow via `zcp` MCP tools. Don't shell out to `zcli`.**

## Notes

- `initCommands` runs `bundle exec ruby migrate.rb` under `zsc execOnce ${appVersionId} --retryUntilSuccessful` — migrations fire once per deploy across all containers, with retry for transient DB startup delays.
- Dev bundle installs all gems (including the `development` group) into `vendor/bundle` during build, so the agent does not need to `bundle install` after SSHing in.
