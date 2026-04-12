#!/usr/bin/env bash
set -euo pipefail

TOOL_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SNAPSHOT_MANIFEST_PATH="$TOOL_ROOT/release/public-stage.manifest"
OVERLAY_MANIFEST_PATH="$TOOL_ROOT/release/public-stage-overlay.manifest"
PRUNE_MANIFEST_PATH="$TOOL_ROOT/release/public-stage-prune.manifest"
OVERRIDES_DIR="$TOOL_ROOT/release/public-stage-overrides"
VERSION_OVERRIDES_ROOT="$TOOL_ROOT/release/public-stage-version-overrides"
TARGET_DIR="${1:-$TOOL_ROOT/../auto314-public-stage}"
SOURCE_DIR="${2:-$TOOL_ROOT}"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/auto314-public-stage.XXXXXX")"
SNAPSHOT_REF=""
VERSION_OVERRIDE_DIR=""

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

if ! command -v rsync >/dev/null 2>&1; then
  echo "rsync is required to build the public-stage copy." >&2
  exit 1
fi

copy_manifest() {
  local manifest_path="$1"
  local root_dir="$2"

  while IFS= read -r path || [[ -n "$path" ]]; do
    [[ -z "$path" || "$path" =~ ^# ]] && continue

    local source_path="$root_dir/$path"
    local target_path="$TMP_DIR/$path"

    if [[ ! -e "$source_path" ]]; then
      echo "Manifest path missing: $path (from $manifest_path)" >&2
      exit 1
    fi

    mkdir -p "$(dirname "$target_path")"

    if [[ -d "$source_path" ]]; then
      mkdir -p "$target_path"
      rsync -a "$source_path/" "$target_path/"
    else
      rsync -a "$source_path" "$target_path"
    fi
  done < "$manifest_path"
}

copy_manifest "$SNAPSHOT_MANIFEST_PATH" "$SOURCE_DIR"
copy_manifest "$OVERLAY_MANIFEST_PATH" "$TOOL_ROOT"

if [[ -f "$PRUNE_MANIFEST_PATH" ]]; then
  while IFS= read -r path || [[ -n "$path" ]]; do
    [[ -z "$path" || "$path" =~ ^# ]] && continue
    rm -rf "$TMP_DIR/$path"
  done < "$PRUNE_MANIFEST_PATH"
fi

if [[ -d "$OVERRIDES_DIR" ]]; then
  rsync -a "$OVERRIDES_DIR/" "$TMP_DIR/"
fi

if command -v git >/dev/null 2>&1 && git -C "$SOURCE_DIR" rev-parse --short HEAD >/dev/null 2>&1; then
  SNAPSHOT_REF="$(git -C "$SOURCE_DIR" rev-parse --short HEAD)"
  VERSION_OVERRIDE_DIR="$VERSION_OVERRIDES_ROOT/$SNAPSHOT_REF"
  if [[ -d "$VERSION_OVERRIDE_DIR" ]]; then
    rsync -a "$VERSION_OVERRIDE_DIR/" "$TMP_DIR/"
  fi
fi

mkdir -p "$TARGET_DIR"
rsync -a --delete --exclude '.git/' "$TMP_DIR/" "$TARGET_DIR/"

cat <<EOF
Prepared public-stage copy:
  release tooling:  $TOOL_ROOT
  source snapshot:  $SOURCE_DIR
  snapshot list:   $SNAPSHOT_MANIFEST_PATH
  release overlay: $OVERLAY_MANIFEST_PATH
  release prune:   $PRUNE_MANIFEST_PATH
  overrides:       $OVERRIDES_DIR
  snapshot ref:    ${SNAPSHOT_REF:-unknown}
  version patch:   ${VERSION_OVERRIDE_DIR:-none}
  target:          $TARGET_DIR

Next steps:
  1. cd "$TARGET_DIR"
  2. review git diff / git status
  3. verify repo links, env placeholders, and deploy config
  4. push manually to the public mirror when ready
EOF
