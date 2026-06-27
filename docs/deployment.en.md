# Deployment

English | [简体中文](deployment.md)

## 1. Prepare `.env`

```bash
cp .env.example .env
nano .env
```

Must be replaced:

```text
KEY_VAULTS_SECRET
AUTH_SECRET
POSTGRES_PASSWORD
RUSTFS_ACCESS_KEY
RUSTFS_SECRET_KEY
SEARXNG_SECRET
```

Generate with:

```bash
# KEY_VAULTS_SECRET and AUTH_SECRET
openssl rand -base64 32

# POSTGRES_PASSWORD, RUSTFS_SECRET_KEY, and SEARXNG_SECRET can use hex
openssl rand -hex 32
```

Fill model providers as needed:

```text
OPENAI_API_KEY
ANTHROPIC_API_KEY
GOOGLE_API_KEY
DEEPSEEK_API_KEY
OPENROUTER_API_KEY
```

Services still start without a model key, but real model calls will fail until one is set.

## 2. Fresh deploy

```bash
sudo bash deploy.sh fresh --yes
```

The script performs:

```text
base packages, UFW, swap
Docker CE
render /opt/lobehub
start LobeHub, PostgreSQL, Redis, RustFS, SearXNG
install the daily backup cron
run local port and service health checks
```

## 3. Public access (Cloudflare Tunnel + domain)

Expose it on your own domain: serve the app at `chat.<domain>` and storage at
`s3.<domain>`, no open ports, TLS terminated at the Cloudflare edge. Set in `.env`:

```env
COMPOSE_PROFILES=tunnel
CF_TUNNEL_TOKEN=<your tunnel token>
APP_URL=https://chat.<domain>
S3_ENDPOINT=https://s3.<domain>
S3_PUBLIC_DOMAIN=https://s3.<domain>
RUSTFS_CORS_ALLOWED_ORIGINS=https://chat.<domain>
AUTH_ALLOWED_EMAILS=you@example.com,teammate@example.com
```

For the full walkthrough — create the tunnel, add the two hostnames (origin is
**HTTP**: `http://127.0.0.1:3210` and `http://127.0.0.1:9000`), start, verify,
add users / rotate keys — see [Public access](public-access.en.md). When done,
open `https://chat.<domain>`.

> Debug only (optional): before the domain is set up you can reach it over an SSH
> tunnel — `ssh -L 3210:127.0.0.1:3210 <server-alias>`, then open
> `http://127.0.0.1:3210` (add `-L 9001:127.0.0.1:9001` for the RustFS console).

## 4. Verify

```bash
sudo bash deploy.sh verify
```

Key checks:

```text
lobehub, lobe-postgres, lobe-redis, lobe-rustfs, lobe-searxng are up
3210, 9000, 9001, 15432, 16379, 18080 listen on 127.0.0.1 only
PostgreSQL / Redis / RustFS health checks pass
http://127.0.0.1:3210 returns an HTTP response
```

## 5. Hardening and operations

Before going public, confirm: `AUTH_ALLOWED_EMAILS` allowlist is set,
`RUSTFS_CORS_ALLOWED_ORIGINS` equals the app domain, and no secret is left at its
default. For day-to-day operations (add users, rotate keys, backup, restart,
troubleshoot) see [Operations](operations.en.md) and
[Troubleshooting](troubleshooting.en.md).
