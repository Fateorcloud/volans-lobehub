# 开源发布检查清单

[English](open-source-release.en.md) | 简体中文

发布或更新公开仓库前，过一遍这份清单。

## 必备文件

- `README.md` 与 `README.en.md` 描述 LobeHub 部署。
- 当前分支不含 NewAPI、Open WebUI、图站文件。
- 本（纯 LobeHub）仓库不含 xui/NAT 文件。
- `.env.example` 只含占位符。
- `.gitignore` 排除生成的凭证、数据库、备份与日志。
- `LICENSE` 存在。
- `SECURITY.md` 说明密钥处理与本机端口边界。
- `scripts/80_security_scan.sh` 通过。

## 隐私审查

确认仓库不包含：

- 应保持私有的真实域名。
- 真实 VPS IP 地址。
- 真实模型供应商 API key。
- 真实 `KEY_VAULTS_SECRET`、`AUTH_SECRET`、PostgreSQL 密码、RustFS key 或 SearXNG secret。
- SSH 私钥、公钥或 known_hosts 文件。
- `postgres_data/`、`redis_data/`、`rustfs_data/`、`rustfs_logs/` 或备份归档。
- 私有部署笔记。

## 建议的发布命令

```bash
bash scripts/80_security_scan.sh
git status --short
git add .
git commit -m "docs: update"
git push
```

建议的仓库简介：

```text
One-command self-hosted LobeHub deploy — Docker Compose (PostgreSQL/PGVector,
Redis, RustFS S3, SearXNG), optional Cloudflare Tunnel for public access.
```
