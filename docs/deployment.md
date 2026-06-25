# 部署流程

## 1. 准备 `.env`

```bash
cp .env.example .env
nano .env
```

必须替换：

```text
KEY_VAULTS_SECRET
AUTH_SECRET
POSTGRES_PASSWORD
RUSTFS_ACCESS_KEY
RUSTFS_SECRET_KEY
SEARXNG_SECRET
```

生成方式：

```bash
# KEY_VAULTS_SECRET and AUTH_SECRET
openssl rand -base64 32

# POSTGRES_PASSWORD, RUSTFS_SECRET_KEY, and SEARXNG_SECRET can use hex
openssl rand -hex 32
```

按需填写模型供应商：

```text
OPENAI_API_KEY
ANTHROPIC_API_KEY
GOOGLE_API_KEY
DEEPSEEK_API_KEY
OPENROUTER_API_KEY
```

没有模型 key 时服务仍可启动，但不能真正发起模型调用。

## 2. Fresh 部署

```bash
sudo bash deploy.sh fresh --yes
```

脚本会执行：

```text
基础软件包、UFW、swap
Docker CE
渲染 /opt/lobehub
启动 LobeHub、PostgreSQL、Redis、RustFS、SearXNG
安装每日备份 cron
执行本机端口和服务健康检查
```

## 3. 公网访问（Cloudflare Tunnel + 域名）

通过你自己的域名公开访问：App 走 `chat.<域名>`、文件存储走 `s3.<域名>`，不开公网端口、
TLS 在 Cloudflare 边缘完成。在 `.env` 配好：

```env
COMPOSE_PROFILES=tunnel
CF_TUNNEL_TOKEN=<你的隧道 token>
APP_URL=https://chat.<域名>
S3_ENDPOINT=https://s3.<域名>
S3_PUBLIC_DOMAIN=https://s3.<域名>
RUSTFS_CORS_ALLOWED_ORIGINS=https://chat.<域名>
AUTH_ALLOWED_EMAILS=you@example.com,teammate@example.com
```

建隧道、加两个主机名（回源填 **HTTP**：`http://127.0.0.1:3210`、`http://127.0.0.1:9000`）、
启动、验证、加人/换 key 的完整步骤见 [公开部署](public-access.md)。配置完成后浏览器打开
`https://chat.<域名>` 即可。

> 仅调试用（可选）：域名未配好前，可临时用 SSH 隧道
> `ssh -L 3210:127.0.0.1:3210 <server-alias>` 访问 `http://127.0.0.1:3210`
> （需要 RustFS 控制台再加 `-L 9001:127.0.0.1:9001`）。

## 4. 验证

```bash
sudo bash deploy.sh verify
```

重点确认：

```text
lobehub, lobe-postgres, lobe-redis, lobe-rustfs, lobe-searxng 已启动
3210, 9000, 9001, 15432, 16379, 18080 只监听 127.0.0.1
PostgreSQL / Redis / RustFS 健康检查通过
http://127.0.0.1:3210 返回 HTTP 响应
```

## 5. 加固与运维

公网开放前确认：已设 `AUTH_ALLOWED_EMAILS` 白名单、`RUSTFS_CORS_ALLOWED_ORIGINS` 等于 App
域名、各密钥均非默认值。日常运维（加人、换 key、备份、重启、排错）见
[运维手册](operations.md) 与 [排障](troubleshooting.md)。
