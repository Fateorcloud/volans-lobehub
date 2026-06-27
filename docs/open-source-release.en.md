# Open source release checklist

English | [简体中文](open-source-release.md)

Use this checklist before publishing or updating the public repository.

## Required files

- `README.md` and `README.en.md` describe the LobeHub deployment.
- NewAPI, Open WebUI, and image-site files are absent from the current branch.
- xui/NAT files are absent from this LobeHub-only repository.
- `.env.example` contains placeholders only.
- `.gitignore` excludes generated credentials, databases, backups, and logs.
- `LICENSE` is present.
- `SECURITY.md` documents secret handling and local port boundaries.
- `scripts/80_security_scan.sh` passes.

## Privacy review

Confirm the repository does not contain:

- Real domains that should remain private.
- Real VPS IP addresses.
- Real provider API keys.
- Real `KEY_VAULTS_SECRET`, `AUTH_SECRET`, PostgreSQL passwords, RustFS keys,
  or SearXNG secrets.
- SSH private keys, public keys, or known-hosts files.
- `postgres_data/`, `redis_data/`, `rustfs_data/`, `rustfs_logs/`, or backup archives.
- Private deployment notes.

## Suggested release commands

```bash
bash scripts/80_security_scan.sh
git status --short
git add .
git commit -m "docs: update"
git push
```

Recommended repository description:

```text
One-command self-hosted LobeHub deploy — Docker Compose (PostgreSQL/PGVector,
Redis, RustFS S3, SearXNG), optional Cloudflare Tunnel for public access.
```
