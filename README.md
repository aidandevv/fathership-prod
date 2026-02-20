# Fathership (Archived Learning Project)

Fathership is a Ruby on Rails app I built while learning full-stack development.
This repository is public as a portfolio/learning artifact, not as an open-source distributable.

## Status

- Archived/portfolio project.
- Best-effort maintenance only.
- Shared for code history and learning context.

## License

This repository is **All Rights Reserved**. See `LICENSE`.

## Stack

- Ruby `3.3.3`
- Rails `7.1`
- PostgreSQL
- Devise
- Hotwire (Turbo + Stimulus)
- Tailwind CSS

## Local Setup

1. Use Ruby 3.3.3 and Bundler 2.5.11:

```bash
rbenv install 3.3.3 -s
rbenv local 3.3.3
gem install bundler -v 2.5.11
```

2. Install gems:

```bash
bundle install
```

3. Copy env template:

```bash
cp .env.example .env
```

4. Start Postgres:

```bash
docker compose up -d db
```

5. Create/migrate DB:

```bash
bin/rails db:create db:migrate
```

6. Run app:

```bash
bin/dev
```

## Environment Variables

- Required in production: `SECRET_KEY_BASE`, `DATABASE_URL`
- Optional AI settings: `OPENAI_ACCESS_TOKEN`, `OPENAI_MODEL` (default `gpt-5-nano`), `OPENAI_MAX_TOKENS`, `OPENAI_TEMPERATURE`, `OPENAI_REQUEST_TIMEOUT`, `OPENAI_RETRY_COUNT`, `OPENAI_RETRY_BASE_DELAY`, `CHAT_CONTEXT_TURN_LIMIT`, `CHAT_MESSAGE_CHAR_LIMIT`

If `OPENAI_ACCESS_TOKEN` is not set, chats fall back to local responses.
For lowest cost, use `OPENAI_MODEL=gpt-5-nano`.

## Notes for Low-Cost Deploys

- `WEB_CONCURRENCY=1`
- `RAILS_MAX_THREADS=3` to `5`
- `RAILS_SERVE_STATIC_FILES=1`
- Use low-cost OpenAI model/token limits or run without OpenAI key

## Feedback

Please use GitHub Issues on this repository.
