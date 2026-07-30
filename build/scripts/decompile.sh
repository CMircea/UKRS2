#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <file.grf> [extra grfcodec args...]"
  exit 1
fi

INPUT="$1"
shift || true

exec grfcodec -d "$INPUT" "$@"
