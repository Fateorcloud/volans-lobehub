# Operations

English | [简体中文](operations.md)

## Service status

```bash
cd /opt/lobehub
docker compose ps
docker compose logs -f lobehub
docker compose logs -f lobe-postgres
docker compose logs -f lobe-rustfs
docker compose logs -f lobe-searxng
```

## Verify

```bash
sudo bash deploy.sh verify
# or, in the deployed directory:
sudo /opt/lobehub/scripts/healthcheck.sh
```

The verification script checks:

```text
Compose service status
whether local ports are wrongly bound to the public interface
PostgreSQL, Redis, RustFS, SearXNG basic health
the LobeHub HTTP entry
```

## Start, stop, update

```bash
cd /opt/lobehub
docker compose pull
docker compose up -d
docker compose restart lobehub
```

Back up before updating:

```bash
sudo bash /opt/lobehub/backup/lobehub_backup.sh
```

## Backup

```bash
sudo bash deploy.sh backup
```

Default output:

```text
/opt/lobehub/backup/postgres_lobechat_YYYY-MM-DD_HHMMSS.sql.gz
/opt/lobehub/backup/rustfs_data_YYYY-MM-DD_HHMMSS.tar.gz
```

Redis uses AOF persistence; the backup script also triggers one `BGSAVE`.

## Repair rendered files

```bash
sudo bash deploy.sh repair --yes
```

This re-renders the compose file, bucket policy, SearXNG config, and health-check
script, while preserving the existing `.env` and data directories.

## Common ports

During the local test phase these ports must listen on `127.0.0.1` only:

```text
3210  LobeHub
9000  RustFS S3 API
9001  RustFS console
15432 PostgreSQL
16379 Redis
18080 SearXNG
```
