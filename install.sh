#!/usr/bin/env bash
# Install the Tabs Under Spaces layout and its custom mod for the current user.

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
HERDR_HOME="$CONFIG_HOME/herdr-app"
LAYOUT_TARGET="$HERDR_HOME/layouts/main-tabs.json"
PREVIEW_TARGET="$HERDR_HOME/layouts/main-tabs.png"
MOD_TARGET="$HERDR_HOME/mods/spaces-with-tabs"
BACKUP_SUFFIX=.before-herdr-spaces-tabs

fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

[[ -d "$HOME" ]] || fail "HOME is not set to a directory"
[[ -f "$SCRIPT_DIR/layouts/main-tabs.json" ]] || fail "layout file is missing"
[[ -f "$SCRIPT_DIR/layouts/main-tabs.png" ]] || fail "layout preview is missing"
[[ -f "$SCRIPT_DIR/mods/spaces-with-tabs/main.js" ]] || fail "spaces-with-tabs/main.js is missing"
[[ -f "$SCRIPT_DIR/mods/spaces-with-tabs/mod.json" ]] || fail "spaces-with-tabs/mod.json is missing"
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
  local backup="${MOD_TARGET}${BACKUP_SUFFIX}"
  local differs=false
  local file

  [[ -d "$MOD_TARGET" || -L "$MOD_TARGET" ]] || return 0
  for file in main.js mod.json jsconfig.json; do
    if [[ -e "$SCRIPT_DIR/mods/spaces-with-tabs/$file" ]] && \
       ! cmp -s "$SCRIPT_DIR/mods/spaces-with-tabs/$file" "$MOD_TARGET/$file" 2>/dev/null; then
      differs=true
    fi
  done
  if [[ "$differs" == true && ! -e "$backup" && ! -L "$backup" ]]; then
    cp -a "$MOD_TARGET" "$backup"
    printf 'Backed up %s to %s\n' "$MOD_TARGET" "$backup"
  fi
}

mkdir -p "$HERDR_HOME/layouts" "$HERDR_HOME/mods"
[[ ! -L "$MOD_TARGET" ]] || fail "$MOD_TARGET is a symlink; move it aside before installing"
backup_file_if_needed "$SCRIPT_DIR/layouts/main-tabs.json" "$LAYOUT_TARGET"
backup_file_if_needed "$SCRIPT_DIR/layouts/main-tabs.png" "$PREVIEW_TARGET"
backup_mod_if_needed

install -m 0644 "$SCRIPT_DIR/layouts/main-tabs.json" "$LAYOUT_TARGET"
install -m 0644 "$SCRIPT_DIR/layouts/main-tabs.png" "$PREVIEW_TARGET"
mkdir -p "$MOD_TARGET"
for file in main.js mod.json jsconfig.json; do
  [[ ! -f "$SCRIPT_DIR/mods/spaces-with-tabs/$file" ]] || \
    install -m 0644 "$SCRIPT_DIR/mods/spaces-with-tabs/$file" "$MOD_TARGET/$file"
done

herdr-app check "$MOD_TARGET"
if herdr-app status >/dev/null 2>&1; then
  herdr-app do layout.switch '{"name":"main-tabs"}'
else
  printf 'Open Herdr, then run: herdr-app do layout.switch '\''{"name":"main-tabs"}'\''\n'
fi

printf '\nTabs Under Spaces is installed.\n'
