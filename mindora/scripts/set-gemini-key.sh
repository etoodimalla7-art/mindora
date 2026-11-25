#!/usr/bin/env bash
# Safely set GEMINI_API_KEY in .env.
# Accepts both legacy (AIza*) and new (AQ.*) key formats.
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <gemini_api_key>"
  echo "Get a key at https://aistudio.google.com/app/apikey"
  exit 1
fi

KEY="$1"
ENV_FILE="/workspaces/mindora/.env"

if [ ${#KEY} -lt 20 ]; then
  echo "✗ Key looks too short (${#KEY} chars)."
  exit 1
fi

python3 - "$KEY" "$ENV_FILE" <<'PY'
import re, sys, pathlib
key, env_path = sys.argv[1], sys.argv[2]
p = pathlib.Path(env_path)
s = p.read_text()
if re.search(r'^GEMINI_API_KEY=', s, flags=re.M):
    s = re.sub(r'^GEMINI_API_KEY=.*$', f'GEMINI_API_KEY={key}', s, flags=re.M)
else:
    s += f'\nGEMINI_API_KEY={key}\n'
p.write_text(s)
print(f'✓ GEMINI_API_KEY set ({len(key)} chars, starts with {key[:3]}...)')
PY
