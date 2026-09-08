#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
source_skill="$repo_root/SKILL.md"
destination_root="${1:-$HOME/.scout/m-skills}"
destination_dir="$destination_root/scout-brainstem-bootstrap"
destination="$destination_dir/SKILL.md"

if [[ ! -f "$source_skill" ]]; then
  printf 'Repository SKILL.md was not found at %s\n' "$source_skill" >&2
  exit 1
fi

mkdir -p "$destination_dir"
cp "$source_skill" "$destination"
cmp --silent "$source_skill" "$destination"

if command -v shasum >/dev/null 2>&1; then
  digest="$(shasum -a 256 "$destination" | awk '{print $1}')"
else
  digest="$(sha256sum "$destination" | awk '{print $1}')"
fi

printf '{"status":"installed","name":"scout-brainstem-bootstrap","path":"%s","sha256":"%s"}\n' \
  "$destination" "$digest"
