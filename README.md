# Ruby Hello World Recipe App

<!-- #ZEROPS_EXTRACT_START:intro# -->
A minimal [Ruby](https://www.ruby-lang.org/) web application built with [Sinatra](https://sinatrarb.com/) and [Puma](https://puma.io/), connected to [PostgreSQL](https://www.postgresql.org/) on [Zerops](https://zerops.io). Demonstrates idempotent database migrations and a health-check endpoint that queries live data.
Used within [Ruby Hello World recipe](https://app.zerops.io/recipes/ruby-hello-world) for [Zerops](https://zerops.io) platform.
<!-- #ZEROPS_EXTRACT_END:intro# -->

⬇️ **Full recipe page and deploy with one-click**

[![Deploy on Zerops](https://github.com/zeropsio/recipe-shared-assets/blob/main/deploy-button/light/deploy-button.svg)](https://app.zerops.io/recipes/ruby-hello-world?environment=small-production)

![ruby cover](https://github.com/zeropsio/recipe-shared-assets/blob/main/covers/svg/cover-ruby.svg)

## Integration Guide

<!-- #ZEROPS_EXTRACT_START:integration-guide# -->

### 1. Adding `zerops.yaml`
The main application configuration file you place at the root of your repository, it tells Zerops how to build, deploy and run your application.

```yaml
zerops:

  # Production setup — bundle only runtime gems, deploy minimal
  # artifacts. Used for stage and all production environments.
  - setup: prod

    build:
      base: ruby@3.4

      # BUNDLE_DEPLOYMENT=1 requires Gemfile.lock (reproducible),
      # installs gems to vendor/bundle, and skips development gems
      # — so only production dependencies are bundled and deployed.
      envVariables:
        BUNDLE_PATH: vendor/bundle
        BUNDLE_DEPLOYMENT: "1"
        BUNDLE_WITHOUT: development

      buildCommands:
        - bundle install

      # Deploy the bundled gems alongside source and the migration
      # script. Gemfile + lock must be present so 'bundle exec'
      # resolves gems at runtime without re-installing them.
      deployFiles:
        - ./vendor
        - ./Gemfile
        - ./Gemfile.lock
        - ./config.ru
        - ./src
        - ./migrate.rb

      # Restore vendor/bundle from the previous build — bundle
      # install then only fetches gems that changed in Gemfile.lock.
      cache:
        - vendor

    # Readiness check: Zerops polls GET / before routing traffic to
    # a new runtime container, ensuring zero-downtime deployments.
    deploy:
      readinessCheck:
        httpGet:
          port: 8080
          path: /

    run:
      base: ruby@3.4

      # Run the migration once per deploy across all containers.
      # initCommands execute before 'start' — the database schema
      # is ready when the app boots. zsc execOnce prevents parallel
      # containers from racing to run the same migration.
      # --retryUntilSuccessful handles transient DB startup delays.
      initCommands:
        - zsc execOnce ${appVersionId} --retryUntilSuccessful -- bundle exec ruby migrate.rb

      ports:
        - port: 8080
          httpSupport: true

      envVariables:
        RACK_ENV: production
        # Tell bundle exec where the vendored gems are and that
        # the development group was excluded at build time —
        # prevents Bundler from failing on missing dev gems.
        BUNDLE_PATH: vendor/bundle
        BUNDLE_WITHOUT: development
        DB_NAME: db
        # Referencing variables: ${db_hostname} resolves to the
        # 'db' service's internal hostname — Zerops injects these
        # at runtime from the database service's generated vars.
        DB_HOST: ${db_hostname}
        DB_PORT: ${db_port}
        DB_USER: ${db_user}
        DB_PASS: ${db_password}

      # Puma is the production Rack server. -b tcp://0.0.0.0
      # ensures it binds to all interfaces, not just localhost.
      start: bundle exec puma -p 8080 -b tcp://0.0.0.0

  # Development setup — deploy full source for live SSH
  # development. The container stays idle ('zsc noop'); the
  # developer SSHs in and starts the app manually after Zerops
  # runs the migration and prepares the workspace.
  - setup: dev

    build:
      base: ruby@3.4

      # Install all gems (including dev group) into vendor/bundle
      # so they are available when the developer SSHs in — no
      # 'bundle install' needed after connecting.
      envVariables:
        BUNDLE_PATH: vendor/bundle

      buildCommands:
        - bundle install

      # Deploy the entire working directory — source, vendor, and
      # zerops.yaml — so the developer can edit and push to other
      # services directly from the SSH session.
      deployFiles: ./

      cache:
        - vendor

    run:
      base: ruby@3.4

      # Migration runs once per deploy — database schema and seed
      # data are ready when the developer SSHs in.
      initCommands:
        - zsc execOnce ${appVersionId} --retryUntilSuccessful -- bundle exec ruby migrate.rb

      ports:
        - port: 8080
          httpSupport: true

      envVariables:
        RACK_ENV: development
        BUNDLE_PATH: vendor/bundle
        DB_NAME: db
        DB_HOST: ${db_hostname}
        DB_PORT: ${db_port}
        DB_USER: ${db_user}
        DB_PASS: ${db_password}

      # Container stays idle — start the app from SSH:
      #   bundle exec puma -p 8080 -b tcp://0.0.0.0
      # For auto-reload during development:
      #   bundle exec rerun -- puma -p 8080 -b tcp://0.0.0.0
      start: zsc noop --silent
```
<!-- #ZEROPS_EXTRACT_END:integration-guide# -->
