#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail=0

# Only scan files that would actually be published: git-tracked plus untracked
# files NOT covered by .gitignore. This keeps local-only private files (.env,
# AUTO-DEPLOY-PRIVATE.md, CONTEXT.md, server-backups/, ...) out of the scan, so
# real production domains/IPs living in those don't trigger false positives.
# Falls back to a filesystem walk when run outside a git work tree (e.g. from a
# downloaded tarball).
if git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  USE_GIT=1
else
  USE_GIT=0
fi

list_files() {
  if [[ "$USE_GIT" == 1 ]]; then
    git ls-files -z --cached --others --exclude-standard
  else
    find . \
      -path ./.git -prune -o \
      -path ./postgres_data -prune -o \
      -path ./redis_data -prune -o \
      -path ./rustfs_data -prune -o \
      -path ./rustfs_logs -prune -o \
      -path ./backup -prune -o \
      -path ./server-backups -prune -o \
      -type f \
      ! -name '*.zip' \
      ! -name '*.tgz' \
      ! -name '*.tar.gz' \
      ! -name '*.7z' \
      ! -name '*.rar' \
      -print0
  fi
}

scan_pattern() {
  local name="$1"
  local pattern="$2"
  local output

  output="$(
    cd "$ROOT" &&
    list_files | xargs -0 grep -nEI "$pattern" 2>/dev/null || true
  )"

  if [[ -n "$output" ]]; then
    printf '[security-scan][FAIL] %s\n%s\n' "$name" "$output" >&2
    fail=1
  fi
}

scan_pattern "OpenAI-compatible token" '(^|[^A-Za-z0-9_])(sk-[A-Za-z0-9_-]{20,})'
scan_pattern "GitHub token" '(ghp_[A-Za-z0-9_]{20,}|github_pat_[A-Za-z0-9_]{20,})'
scan_pattern "Private key" 'BEGIN (OPENSSH|RSA|EC|DSA) PRIVATE KEY'
scan_pattern "Cloudflare JWT-like token" 'eyJ[A-Za-z0-9_-]{30,}\.[A-Za-z0-9_-]{30,}\.[A-Za-z0-9_-]{20,}'
scan_pattern "Production Volans domain" '(^|[^A-Za-z0-9.-])([A-Za-z0-9-]+\.)?volans\.one([^A-Za-z0-9.-]|$)'
scan_pattern "Known production IP" '(203\.9\.150\.170|141\.239\.74\.52)'

if [[ "$fail" -ne 0 ]]; then
  cat >&2 <<'MSG'
[security-scan] Potential public-release issues found.
Review each match. Use placeholders for docs/examples and keep real secrets out of Git.
MSG
  exit 1
fi

printf '[security-scan] OK: no obvious public-release secrets found.\n'
