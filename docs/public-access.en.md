# Public access: Cloudflare Tunnel + domain

English | [简体中文](public-access.md)

By default `deploy.sh fresh` runs LobeHub on `127.0.0.1` only (local test phase).
To open it to a group of users, a **Cloudflare Tunnel** is the easiest path: no
open ports, TLS terminated at the Cloudflare edge, and the edge also adds
HTTP/2 + compression + static-asset caching (noticeably faster first paint).

Prerequisite: your domain is on Cloudflare. The examples below use `example.com`,
with the app at `chat.example.com` and storage at `s3.example.com`.

## Why two hostnames

LobeHub does not store files itself — it offloads them to S3-compatible storage
(RustFS here). On upload the browser gets a short-lived signed link and **uploads
the file straight to storage**, so large files don't slow the chat server. That
means the storage service (RustFS, `127.0.0.1:9000`) must be reachable by the
user's browser, which needs its own hostname `s3.example.com`. It is just one
extra subdomain on the same host and tunnel, transparent to users.

## Steps

### 1. Create a tunnel in Cloudflare Zero Trust

`Networks → Tunnels → Create a tunnel` (Cloudflared type) → get the **Tunnel
Token**. Under the tunnel's **Public Hostnames**, add two (Cloudflare creates the
DNS records + edge certificates automatically):

| Hostname | Service |
|---|---|
| `chat.example.com` | `http://127.0.0.1:3210` |
| `s3.example.com` | `http://127.0.0.1:9000` |

### 2. Configure `.env`

```env
COMPOSE_PROFILES=tunnel
CF_TUNNEL_TOKEN=<your tunnel token>

APP_URL=https://chat.example.com
INTERNAL_APP_URL=http://127.0.0.1:3210

S3_ENDPOINT=https://s3.example.com
S3_PUBLIC_DOMAIN=https://s3.example.com
S3_ENABLE_PATH_STYLE=1
S3_SET_ACL=0
RUSTFS_CORS_ALLOWED_ORIGINS=https://chat.example.com

# Sign-up allowlist: only these emails/domains may register (empty = anyone).
AUTH_ALLOWED_EMAILS=you@example.com,teammate@example.com

# Hide the first-run "add a few agents" onboarding screen while keeping Market enabled.
FEATURE_FLAGS=-welcome_suggest

# Server-side shared key pool (usable by all logged-in users; a user may also add
# their own private key in Settings).
API_KEY_SELECT_MODE=turn
DEEPSEEK_API_KEY=sk-xxx           # comma-separate to pool multiple: sk-aaa,sk-bbb
```

### 3. Start

```bash
cd /opt/lobehub
docker compose --profile tunnel up -d          # start cloudflared
docker compose up -d --force-recreate lobe rustfs   # apply the new .env
```

Once `COMPOSE_PROFILES=tunnel` is set in `.env`, later `deploy.sh repair` runs
keep the tunnel.

## Verify

```bash
docker logs --tail 30 cloudflare-tunnel        # expect "Registered tunnel connection"
curl -I https://chat.example.com               # 200/302, with content-encoding: br/gzip
```

Open `https://chat.example.com` in a browser: allowlisted emails can register and
sign in; users without a private key use the server-side shared pool; uploading a
file in chat should succeed (the browser uploads directly to `s3.example.com`).

## User and key model

- **Admission**: `AUTH_ALLOWED_EMAILS` decides who can get in. Add someone by
  appending their email, then `docker compose up -d --force-recreate lobe`.
- **Shared pool**: keys in `.env` are usable by every logged-in user, invisible
  and not editable by them.
- **Personal BYOK**: a user adds their own key in Settings (encrypted per user);
  if set, theirs is used, otherwise the shared pool.

## Notes

- Cloudflare's free plan caps a single upload request at about **100MB** (usually
  enough for chat attachments).
- Upload CORS/403 errors: confirm `RUSTFS_CORS_ALLOWED_ORIGINS` equals the app
  domain, `S3_ENDPOINT` uses the `s3.` public hostname, and `S3_ENABLE_PATH_STYLE=1`.
- Keep `CF_TUNNEL_TOKEN` and all keys in `.env` only (it is `.gitignore`d); never
  commit them.
