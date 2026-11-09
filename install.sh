#!/usr/bin/env bash
# Install the compact Tabs Under Spaces layout and its custom mods.

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
HERDR_HOME="$CONFIG_HOME/herdr-app"
LAYOUT_TARGET="$HERDR_HOME/layouts/main-tabs.json"
PREVIEW_TARGET="$HERDR_HOME/layouts/main-tabs.png"
BACKUP_SUFFIX=.before-herdr-spaces-tabs
MODS=(
  spaces-with-tabs
  agents-compact
  tabs-compact
  pane-compact
  workspace-status-compact
  workspace-chrome-compact
)

fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

[[ -d "$HOME" ]] || fail "HOME is not set to a directory"
[[ -f "$SCRIPT_DIR/layouts/main-tabs.json" ]] || fail "layout file is missing"
[[ -f "$SCRIPT_DIR/layouts/main-tabs.png" ]] || fail "layout preview is missing"
command -v herdr-app >/dev/null 2>&1 || fail "herdr-app was not found; install Herdr first"

backup_file_if_needed() {
  local source="$1"
  local target="$2"
  local backup="${target}${BACKUP_SUFFIX}"

  if [[ -e "$target" || -L "$target" ]] && ! cmp -s "$source" "$target" 2>/dev/null; then
    if [[ ! -e "$backup" && ! -L "$backup" ]]; then
      cp -a "$target" "$backup"
      printf 'Backed up %s to %s\n' "$target" "$backup"
    fi
  fi
}

backup_mod_if_needed() {
  local mod="$1"
  local source_dir="$SCRIPT_DIR/mods/$mod"
  local target_dir="$HERDR_HOME/mods/$mod"
  local backup="${target_dir}${BACKUP_SUFFIX}"
  local differs=false
  local file

  [[ -e "$target_dir" || -L "$target_dir" ]] || return 0
  [[ ! -L "$target_dir" ]] || fail "$target_dir is a symlink; move it aside before installing"
  [[ -d "$target_dir" ]] || fail "$target_dir exists and is not a directory"

  for file in main.js mod.json jsconfig.json; do
    if [[ -f "$source_dir/$file" ]] && ! cmp -s "$source_dir/$file" "$target_dir/$file" 2>/dev/null; then
      differs=true
    fi
  done
  if [[ "$differs" == true && ! -e "$backup" && ! -L "$backup" ]]; then
    cp -a "$target_dir" "$backup"
    printf 'Backed up %s to %s\n' "$target_dir" "$backup"
  fi
}

mkdir -p "$HERDR_HOME/layouts" "$HERDR_HOME/mods"
backup_file_if_needed "$SCRIPT_DIR/layouts/main-tabs.json" "$LAYOUT_TARGET"
backup_file_if_needed "$SCRIPT_DIR/layouts/main-tabs.png" "$PREVIEW_TARGET"
for mod in "${MODS[@]}"; do backup_mod_if_needed "$mod"; done

install -m 0644 "$SCRIPT_DIR/layouts/main-tabs.json" "$LAYOUT_TARGET"
install -m 0644 "$SCRIPT_DIR/layouts/main-tabs.png" "$PREVIEW_TARGET"
for mod in "${MODS[@]}"; do
  source_dir="$SCRIPT_DIR/mods/$mod"
  target_dir="$HERDR_HOME/mods/$mod"
  [[ -f "$source_dir/main.js" && -f "$source_dir/mod.json" ]] || \
    fail "package mod is incomplete: $mod"
  mkdir -p "$target_dir"
  for file in main.js mod.json jsconfig.json; do
    [[ ! -f "$source_dir/$file" ]] || install -m 0644 "$source_dir/$file" "$target_dir/$file"
  done
done

for mod in "${MODS[@]}"; do herdr-app check "$HERDR_HOME/mods/$mod"; done
if herdr-app status >/dev/null 2>&1; then
  herdr-app do layout.switch '{"name":"main-tabs"}'
else
  printf 'Open Herdr, then run: herdr-app do layout.switch '\''{"name":"main-tabs"}'\''\n'
fi

printf '\nCompact Tabs Under Spaces is installed.\n'
