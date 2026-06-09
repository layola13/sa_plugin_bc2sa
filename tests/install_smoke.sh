#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "usage: tests/install_smoke.sh <SA_PLUGINS_HOME> <sa-bin>" >&2
  exit 2
fi

home="$1"
sa_bin="$2"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
plugin_current="$home/installed/bc2sa/current"

require_file() {
  local path="$1"
  [[ -f "$path" ]] || {
    echo "missing installed file: $path" >&2
    exit 1
  }
}

require_contains() {
  local needle="$1"
  local path="$2"
  grep -Fq "$needle" "$path" || {
    echo "expected '$needle' in $path" >&2
    exit 1
  }
}

require_file "$plugin_current/libbc2sa.so"
require_file "$plugin_current/sap.json"

grep -Eq '"spawn"[[:space:]]*:[[:space:]]*true' "$plugin_current/sap.json" || {
  echo "installed sap.json missing process.spawn=true" >&2
  exit 1
}
require_contains '/usr/bin/llvm-dis-14' "$plugin_current/sap.json"
require_contains '"HOME"' "$plugin_current/sap.json"
require_contains '"SA_*"' "$plugin_current/sap.json"

if ! skills_out="$(env -u SA_PLUGINS_PATH SA_PLUGINS_HOME="$home" SA_PLUGIN_DEV=1 "$sa_bin" skills 2>&1)"; then
  echo "$skills_out" >&2
  exit 1
fi
if [[ "$skills_out" != *"bc2sa"* ]]; then
  echo "installed skills output missing bc2sa" >&2
  exit 1
fi

command -v llvm-as-14 >/dev/null 2>&1 || {
  echo "missing llvm-as-14 required for bc2sa install smoke test" >&2
  exit 1
}

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
bc_path="$tmpdir/install-smoke.bc"
llvm-as-14 "$script_dir/install_smoke.ll" -o "$bc_path"

if ! translate_out="$(env -u SA_PLUGINS_PATH SA_PLUGINS_HOME="$home" SA_PLUGIN_DEV=1 "$sa_bin" bc2sa "$bc_path" 2>&1)"; then
  echo "$translate_out" >&2
  exit 1
fi

if [[ "$translate_out" != *"@export main() -> i32:"* ]]; then
  echo "bc2sa smoke output missing translated export" >&2
  echo "$translate_out" >&2
  exit 1
fi

if [[ "$translate_out" != *"return 0"* ]]; then
  echo "bc2sa smoke output missing translated return" >&2
  echo "$translate_out" >&2
  exit 1
fi
