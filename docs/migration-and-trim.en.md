# Migration and trim runbook

English | [简体中文](migration-and-trim.md)

This runbook covers migrating a LobeHub deployment to another server, or trimming
an old AI platform down to the new lightweight stack. It uses placeholders only
and records no real servers, tokens, passwords, or private domains.

## Module boundaries

| Module | Path / service | Core? | Notes |
|---|---|---|---|
| LobeHub | `lobehub` container | Yes | Front end and server-side main app |
| PostgreSQL/PGVector | `postgres_data/` | Yes | Sessions, users, config, knowledge-base metadata |
| Redis | `redis_data/` | Yes | Cache, sessions, background-task state |
| RustFS/S3 | `rustfs_data/` | Yes | Uploaded files, images, knowledge-base objects |
| SearXNG | `lobe-searxng` | Optional | Online search; can be stopped if unused |
| Old NewAPI/Open WebUI/image site | GitHub `codex/legacy-ai-stack-backup` | No | Backed up; not deployed by the current project |
| xui/NAT | separate deploy project | No | Not part of this repo; maintained by a separate network project |
| Notes / static sites | separate dirs and Nginx | Unrelated | Out of scope for this AI-platform trim |

## Trimming from an old platform

Do not delete old directories or volumes in the first pass. Recommended order:

1. Confirm the old NewAPI/Open WebUI/image-site chain is backed up to the GitHub
   branch `codex/legacy-ai-stack-backup`.
2. Keep the old server's `/opt/Serve`; do not auto-delete volumes.
3. Create `/opt/lobehub` and deploy the new stack.
4. Verify the LobeHub UI, model calls, session persistence, and uploads.
5. If you still need xui/NAT, deploy it with the separate network project at `/opt/xui`.
6. After verification, only stop the old containers — do not delete data.
7. After an observation period, manually decide whether to archive or delete the old stack.

Stop the old containers, for example:

```bash
cd /opt/Serve
docker compose stop
```

Do not auto-delete:

```text
pg_data/
newapi_data/
open-webui_data/
xui/
server-backups/
```

The current repo should also no longer carry NewAPI, Open WebUI, or image-site
deploy templates; restore from `codex/legacy-ai-stack-backup` when the old setup
is needed.

## Migrating to a second server

Back up on the old server:

```bash
sudo bash /opt/lobehub/backup/lobehub_backup.sh
```

Copy to the new server:

```text
/opt/lobehub/.env
postgres_lobechat_*.sql.gz
rustfs_data_*.tar.gz
```

Deploy an empty stack on the new server:

```bash
git clone https://github.com/Fateorcloud/volans-lobehub.git
cd volans-lobehub
cp .env.example .env
nano .env
sudo bash deploy.sh fresh --yes
```

Restore PostgreSQL:

```bash
cd /opt/lobehub
gzip -dc /path/to/postgres_lobechat_YYYY-MM-DD_HHMMSS.sql.gz \
  | docker compose exec -T postgresql psql -U postgres lobechat
```

Restore RustFS:

```bash
cd /opt/lobehub
docker compose stop rustfs
sudo rm -rf rustfs_data
mkdir -p rustfs_data
tar xzf /path/to/rustfs_data_YYYY-MM-DD_HHMMSS.tar.gz -C rustfs_data
docker compose up -d rustfs rustfs-init lobehub
```

Final verification:

```bash
sudo bash deploy.sh verify
```

## Checks before decommissioning the old server

```bash
sudo bash deploy.sh verify
ssh -L 3210:127.0.0.1:3210 -L 9000:127.0.0.1:9000 <new-server>
```

Confirm:

- LobeHub can log in.
- At least one model provider call succeeds.
- After creating a session and restarting compose, the record still exists.
- Uploaded files or image paths are reachable.
- Backup files can be extracted.
- No private `.env`, API keys, or backup archives entered Git.
