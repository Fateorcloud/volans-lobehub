# Troubleshooting

English | [简体中文](troubleshooting.md)

## LobeHub won't open

Check the services:

```bash
cd /opt/lobehub
docker compose ps
docker compose logs --tail=200 lobehub
```

Check local ports:

```bash
curl -I http://127.0.0.1:3210/
ss -lntup | grep ':3210'
```

If nothing is listening, look in the `lobehub` logs for database-migration or
environment-variable errors first.

## Compose config fails

```bash
cd /opt/lobehub
docker compose config --quiet
```

Common causes:

```text
.env is missing
a required secret is still CHANGE_ME
AUTH_SECRET contains spaces but is not quoted
a port variable is not a number
```

## Database connection fails

LobeHub uses host networking and connects to the host loopback:

```text
postgresql://postgres:<password>@127.0.0.1:15432/lobechat
```

Check:

```bash
cd /opt/lobehub
docker compose exec -T postgresql pg_isready -U postgres
ss -lntup | grep ':15432'
```

## Uploads or images don't work

Local-phase `.env` defaults:

```env
S3_ENDPOINT=http://127.0.0.1:9000
S3_ENABLE_PATH_STYLE=1
S3_SET_ACL=0
```

For local access an SSH tunnel must forward both `3210` and `9000`:

```bash
ssh -L 3210:127.0.0.1:3210 -L 9000:127.0.0.1:9000 <server-alias>
```

Check RustFS:

```bash
curl -I http://127.0.0.1:9000/health
docker compose logs --tail=200 lobe-rustfs
docker compose logs --tail=200 lobe-rustfs-init
```

On a public domain, instead confirm `RUSTFS_CORS_ALLOWED_ORIGINS` equals the app
domain and `S3_ENDPOINT`/`S3_PUBLIC_DOMAIN` use the `s3.` public hostname.

## Models unavailable

Check that `.env` has the matching provider key:

```text
OPENAI_API_KEY
ANTHROPIC_API_KEY
GOOGLE_API_KEY
DEEPSEEK_API_KEY
OPENROUTER_API_KEY
```

If you use a compatible gateway, set that provider's proxy URL, e.g.:

```env
OPENAI_PROXY_URL=https://api.example.com/v1
```

Restart after editing `.env`:

```bash
cd /opt/lobehub
docker compose up -d --force-recreate lobehub
```

If you need outbound proxying, maintain the proxy in a separate network project
and only set `HTTP_PROXY` / `HTTPS_PROXY` in this project's `.env`.

## Ports wrongly exposed to the public

The verification script will fail:

```bash
sudo bash deploy.sh verify
```

These ports must not listen on `0.0.0.0` or `[::]`:

```text
3210
9000
9001
15432
16379
18080
```

Check that compose still uses:

```yaml
127.0.0.1:3210
127.0.0.1:9000
```
