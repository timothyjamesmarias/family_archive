# Family Archive

A family archive for genealogical data and family history: browse photographs,
letters, documents, ledgers, and recordings; read articles; and explore an
interactive family tree. Administrators manage the collection through a
server-rendered admin.

Ported to Rails 8 from an AdonisJS application. Stack: PostgreSQL,
Solid Cache/Queue/Cable, Vite + Tailwind v4, Turbo/Stimulus, a TypeScript
family-tree island, Devise, Mission Control – Jobs.

## Getting started

```bash
docker compose up -d   # Postgres on host port 5433
bin/setup
bin/dev
```

Sign in with the seeded development admin: `admin@example.com` / `password`.

## Everyday commands

```bash
bin/rails test            # unit + integration tests
bin/rails test:system     # system tests (headless Chrome)
npm run test:frontend     # Vitest for the family-tree island
npm run typecheck
bin/rubocop
bin/ci                    # everything CI runs
```

Thumbnail generation needs libvips locally (`brew install vips`).

## Layout

- `app/services` — domain operations (uploads, tree mutations, sanitization)
- `app/queries` — recursive-CTE traversals over the genealogy graph
- `script/gedcom-to-json.mjs` — read-gedcom CLI the GEDCOM importer shells to
- `app/frontend/apps/family-tree` — the tree island (ported as-is; React later)
- `app/frontend/apps/annotations` — the admin photo-annotations editor (React + MUI)
- `lib/generators/admin_scaffold` — generator for admin CRUD sections
- `docs`: see `CLAUDE.md` for architecture notes and conventions

## Deploy

Render, via `render.yaml`. Set `ADMIN_EMAIL`/`ADMIN_PASSWORD` (seeds the admin
account) and the S3 vars for Active Storage uploads: `AWS_ACCESS_KEY_ID`,
`AWS_SECRET_ACCESS_KEY`, `AWS_REGION`, `AWS_S3_BUCKET`, and
`AWS_S3_KEY_PREFIX` (the folder blob keys are generated under).
