# Pull Production Data into Development — Plan

One command, `bin/pull-prod`, replaces the development database with a
fresh copy of production. Production images then load straight from S3
through a read-only IAM user; anything uploaded in development stays on
local disk. Nothing in development can write to the production database or
bucket.

Depends on: the `deploy` Postgres role (part 1, `nixos-server` repo) and the
read-only IAM user (`docs/aws-dev-access-plan.md`).

## Part 1 — Read-only Postgres role for `deploy` (nixos-server)

`deploy` has no sudo, and `su -` needs a terminal for the root password, so
a dump can't be streamed through it. Instead give `deploy` its own
read-only database role. `modules/postgresql.nix` already has
`local all all peer`, so over the Unix socket the OS user `deploy` logs in
as role `deploy` with no password.

`modules/postgresql.nix`:

```nix
ensureUsers = (map (app: { … }) appDatabases) ++ [
  { name = "postgres_exporter"; }
  # Read-only, socket-only: lets `ssh nix-server pg_dump …` pull a copy of
  # an app database for development without root or app passwords.
  { name = "deploy"; }
];
```

and one line in the `db-passwords` script (it already runs psql as
`postgres` after every rebuild; re-granting is a no-op):

```sh
${pkgs.sudo}/bin/sudo -u postgres ${psql} -c "GRANT pg_read_all_data TO deploy;"
```

- `pg_read_all_data` is SELECT on every table in every database, nothing
  else. No host rule is added, so the role is reachable only over the local
  socket, i.e. only by someone already logged in as `deploy`.
- Trade-off: it reads every app's database, not just this one. `deploy` can
  already ship images that connect to those databases, so this grants
  nothing new in practice.

Verify after `nixos-rebuild switch`:

```sh
ssh nix-server 'which pg_dump && psql -d family_archive -c "select count(*) from individuals"'
```

Add a line to `docs/FAMILY-ARCHIVE-SETUP.md` noting the role and why.

## Part 2 — `bin/pull-prod` (this repo)

```sh
#!/usr/bin/env sh
# Replaces the development database with a copy of production.
set -eu

[ "${RAILS_ENV:-development}" = development ] || { echo "development only" >&2; exit 1; }

dump=tmp/prod.dump
ssh nix-server 'pg_dump -Fc family_archive' > "$dump"

# Drop instead of pg_restore --clean: --clean only drops objects in the
# dump, so a table from an unmerged local migration would survive and the
# migrate below would trip over it. --force disconnects a running bin/dev.
docker compose exec -T postgres dropdb -U postgres --force --if-exists family_archive_development
docker compose exec -T postgres createdb -U postgres family_archive_development
docker compose exec -T postgres pg_restore -U postgres --no-owner --no-privileges \
  -d family_archive_development < "$dump"

# The dump says it's production; Rails refuses destructive db: tasks until told otherwise.
bin/rails db:environment:set RAILS_ENV=development
bin/rails db:migrate
```

- Assumes Postgres is running (`bin/setup` / `docker compose up -d`); the
  script doesn't start it.
- Compose and server are both Postgres 17, so `pg_restore` reads the dump.
- The dump stays at `tmp/prod.dump` (gitignored), overwritten each pull.
- Users come over as-is: log in with your production credentials.
- `db:migrate` only does something when the branch has migrations prod
  hasn't run yet; `db/schema.rb` may then show a diff — don't commit it.
- Local files under `storage/` from earlier dev uploads become orphans
  (their blob rows are gone). Harmless; don't `rm -rf storage/` — it also
  holds the dev Solid Queue SQLite file.

## Part 3 — Images from S3, read-only

No app code. Every `active_storage_blobs` row stores its `service_name`.
Production blobs come over tagged `amazon`; development already defines that
service in `config/storage.yml` and uploads new files to `:local`. With
read-only AWS credentials present, Rails reads prod blobs from S3 and keeps
writing dev blobs to disk.

Development config, in a gitignored `.env` (foreman, i.e. `bin/dev`, loads
it automatically):

```sh
AWS_PROFILE=family-archive-dev
AWS_REGION=us-east-2
AWS_S3_BUCKET=marias-family-archive
```

- `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` stay unset, so
  `storage.yml` passes no keys and the AWS SDK falls back to the
  `family-archive-dev` profile in `~/.aws/credentials`. The secret never
  sits in the project directory. (Verify in step 3; if the SDK doesn't fall
  back, put the two keys in `.env` instead.)
- `AWS_S3_KEY_PREFIX` stays unset in development.
- `bin/rails console` doesn't load `.env`; export the three variables there
  if you need prod images from the console.

What happens when development touches a prod blob:

| Action in dev | Result |
|---|---|
| View an image / play audio | Presigned S3 URL, loads |
| Existing thumbnail | Loads — its variant record came over in the dump |
| Thumbnail prod never generated | Shows the original image; nothing tries to generate it |
| Delete an artifact | Dev rows deleted; the purge job fails with AccessDenied; S3 untouched |
| Upload a new file | Goes to `storage/` on disk as usual |

The write protection is IAM's, not the app's: the dev user has no
`PutObject` or `DeleteObject`, so a bug can't change the bucket.

## Steps

1. Part 1 in `nixos-server`; rebuild; run the verify command.
2. Create the IAM user and profile (`docs/aws-dev-access-plan.md`).
3. Add `bin/pull-prod`, the `.env` lines, and a short "Production data"
   section in CLAUDE.md (command, what it replaces, the S3 table above in
   one sentence). Run it; check:
   - `select service_name, count(*) from active_storage_blobs group by 1`
     shows `amazon`;
   - a photo page renders images in `bin/dev`;
   - deleting a throwaway artifact in dev leaves the object in S3
     (`aws s3 ls --profile family-archive-dev s3://marias-family-archive/<key>`).
4. `bin/ci` still green (tests use their own database and the Disk service;
   nothing here touches them).

## Out of scope

- Scrubbing or anonymising data — it's the family's own archive, on your
  own laptop.
- Pulling the Solid Queue/Cache SQLite files — ephemeral by design.
- Terraform / AWS Organizations — later, separately.

## As built

Where the shipped code differs from the plan above, and what the open
checks found. The code and CLAUDE.md are current; this plan is the record
of intent.

- **`bin/pull-prod` `cd`s to the repo root** so `tmp/prod.dump` and
  `docker compose` resolve from any directory. It also has comments on its
  prerequisites, on why the restore runs in the container, and on dumping
  first: if `ssh`/`pg_dump` fails, `set -e` stops before anything is
  dropped.
- **The dump is validated before the drop.** `pg_restore --list` (in the
  container) reads the dump's table of contents; an empty or garbled file
  exits 1, so `set -e` stops before `dropdb`. Checked with an empty file
  ("input file is too short") and 4 KB of random bytes ("does not appear to
  be a valid archive"). It reads only the TOC, so it won't catch a dump cut
  off mid-data; an `ssh` failure is caught by its own exit status.
- **`umask 077`, `rm -f` of the old dump, and `unset DATABASE_URL`.** The
  dump holds production password hashes, so it's owner-only. A stray
  `DATABASE_URL` would point the Rails steps at another database.
- **`db:environment:set` stays.** Review suggested `db:migrate` already
  records the environment (`Migrator#record_environment`). It does, but
  development has two databases (primary + the queue SQLite), so
  `DatabaseTasks.migrate_all` only migrates databases with pending
  versions. On a pull with nothing pending, the primary keeps
  `production`. Reproduced on the scratch database.
- **Thumbnails (table above, corrected).** `TransformJob` is only enqueued
  when a file is attached, and every `variant(:thumb)` call site is behind
  `ArtifactFile#thumbnail?` (`variant_records.any?`), falling back to the
  original. A prod file with no thumbnail shows its original; nothing fails.
  The `ListBucket` rationale in `docs/aws-dev-access-plan.md` was corrected
  for the same reason (`track_variants` is on); the permission stays.
- **`db/schema.rb` changes after every pull**, not only when migrations are
  pending. A dump/restore makes Postgres re-render the `chk_role` check
  constraint (`'FATHER'::character varying::text` instead of
  `…::character varying]::text[]`), and `db:migrate` always dumps the schema.
  The two forms mean the same thing. Don't commit the change (CLAUDE.md says so).
- **The S3 fallback works as assumed.** `storage.yml` renders
  `access_key_id:` and `secret_access_key:` as nil. In aws-sdk-core 3.265,
  `CredentialProviderChain` skips static credentials unless both keys are
  non-empty (`Credentials#set?`). It then skips env credentials (unset) and
  reaches `shared_credentials`, which reads `ENV["AWS_PROFILE"]`. Checked
  offline by building the `amazon` service under `bin/rails runner` with a
  throwaway credentials file. The client got `Aws::SharedCredentials` for
  `family-archive-dev`, region `us-east-2`, and `Blob.service` stayed
  `:local`. No AWS call. No app code was needed: `Blob#service` is
  `services.fetch(service_name)`, and the registry holds every
  `storage.yml` entry.
- **Docker needed no `DOCKER_API_VERSION`.** `docker compose exec -T
  postgres pg_restore --version` works as-is (client API 1.55, Docker
  Desktop server 1.56), so the script has no workaround for it.
- **The Postgres 17 assumption checks out.** The host `pg_restore` (16.10)
  rejects a Postgres 17 custom dump with "unsupported version (1.16) in file
  header". The container's is 17.11.
- **Restore exercised on a scratch database, not production.** A
  `pg_dump -Fc` of the dev database was restored with the script's exact
  `pg_restore --list`/`dropdb`/`createdb`/`pg_restore` commands into `family_archive_pullcheck`
  (exit 0, no errors). It was tagged `production`, `db:environment:set` and
  `db:migrate` were run against it, and it was then dropped.
  `db:environment:set` writes only the primary database, the one restored.
  Steps 1 and 3 (rebuild + verify, a real pull, images in `bin/dev`, the S3
  delete check) are the owner's.
- **nixos-server (ufo-soft/nixos-server#9)**: as planned, plus an `echo`
  after the grant to match the script's other steps. The comment explains
  the socket-only claim more precisely than the plan does. A
  `host all all 127.0.0.1/32 scram-sha-256` rule does match `deploy`, but
  the role has no password, so only peer auth admits it. Checked with
  `nix-instantiate --parse` only; not built or deployed.
- **`db-passwords` now waits for `postgresql-setup.service`.** At the
  pinned nixpkgs, `ensureUsers` runs there, so the GRANT could race
  `CREATE USER deploy` on the first switch, and the oneshot wouldn't retry.
  The same fix covers the existing `ALTER USER` lines on a fresh cluster.
  The unit runs at boot and whenever a rebuild changes it, not on every
  rebuild.
- **Part 1's premise was wrong: `deploy` does have sudo.** On `main`,
  `modules/base.nix` gives it NOPASSWD `sudo -u postgres` for any command,
  plus membership in `docker` (root-equivalent). `ssh nix-server 'sudo -n -u
  postgres pg_dump -Fc family_archive'` would work without part 1. The role
  is kept as least privilege, so routine pulls read as a read-only role
  instead of the superuser. It isn't a new security boundary, and the
  setup doc now says so.
