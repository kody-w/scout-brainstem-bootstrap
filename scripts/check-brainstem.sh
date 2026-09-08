#!/usr/bin/env bash
set -euo pipefail

require_ready=false
if [[ "${1:-}" == "--require-ready" ]]; then
  require_ready=true
fi

url="http://127.0.0.1:7071/health"
body="$(curl --silent --show-error --fail --max-time 3 "$url")"
printf '%s\n' "$body"

if ! grep -Eq '"status"[[:space:]]*:[[:space:]]*"(ok|unauthenticated)"' <<<"$body"; then
  exit 3
fi
if $require_ready && ! grep -Eq '"status"[[:space:]]*:[[:space:]]*"ok"' <<<"$body"; then
  exit 2
fi
