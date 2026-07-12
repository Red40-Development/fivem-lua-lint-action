#!/usr/bin/env bash

set -euo pipefail

REPOSITORY="${FIVEM_LUA_LINT_REPOSITORY:-Red40-Development/fivem-lua-lint-action}"
REF="${FIVEM_LUA_LINT_REF:-main}"
CACHE_DIR="${FIVEM_LUA_LINT_CACHE_DIR:-$HOME/.cache/fivem-lua-lint-action}"
LUACHECK_REPOSITORY="${FIVEM_LUACHECK_REPOSITORY:-Red40-Development/luacheck}"
LUACHECK_BRANCH="${FIVEM_LUACHECK_BRANCH:-fivem-lua}"
LUACHECK_SOURCE_DIR="$CACHE_DIR/luacheck-$LUACHECK_BRANCH"
LUACHECK_TREE="$CACHE_DIR/luarocks-fivem"
LUACHECK_COMMAND="${FIVEM_LUACHECK_BIN:-$HOME/.local/bin/luacheck-fivem}"
LUACHECK_INSTALL_MARKER="$CACHE_DIR/luacheck-install"

usage() {
  cat <<EOF
Usage:
  $0 [lint options and paths...]     Update the cache if needed, then lint
  $0 lint [options and paths...]     Same as above
  $0 update                          Download the latest lint definitions
  $0 install                         Install Lua, LuaRocks, and LuaCheck

Lint options:
  --extra-libs a+b+c                 Add standards from the generated template
  --no-update                        Do not download missing definitions

Environment:
  FIVEM_LUA_LINT_REF                 Git ref to download (default: main)
  FIVEM_LUA_LINT_REPOSITORY          GitHub repository (default: $REPOSITORY)
  FIVEM_LUA_LINT_CACHE_DIR           Cache location (default: $CACHE_DIR)
  FIVEM_LUACHECK_REPOSITORY          LuaCheck repository (default: $LUACHECK_REPOSITORY)
  FIVEM_LUACHECK_BRANCH              LuaCheck branch (default: $LUACHECK_BRANCH)
  LUACHECK_BIN                       Explicit LuaCheck executable
EOF
}

die() {
  echo "ERROR: $*" >&2
  exit 1
}

require_curl() {
  command -v curl >/dev/null 2>&1 || die "curl is required to download the lint definitions"
}

cache_file() {
  printf '%s/%s\n' "$CACHE_DIR" "$1"
}

download_file() {
  local file="$1"
  local destination
  local temporary

  destination=$(cache_file "$file")
  temporary="$destination.tmp.$$"
  mkdir -p "$CACHE_DIR"
  echo "Downloading $file from $REPOSITORY@$REF"
  curl --fail --location --silent --show-error --retry 3 \
    "https://raw.githubusercontent.com/$REPOSITORY/$REF/$file" \
    --output "$temporary"
  test -s "$temporary" || die "downloaded file is empty: $file"
  mv "$temporary" "$destination"
}

update_cache() {
  require_curl
  download_file .luacheckrc.default
  download_file .luacheckrc.generated.template
  echo "Lint definitions updated in $CACHE_DIR"
}

ensure_cache() {
  if [[ ! -s "$(cache_file .luacheckrc.default)" || ! -s "$(cache_file .luacheckrc.generated.template)" ]]; then
    update_cache
  fi
}

find_luacheck() {
  if [[ -n "${LUACHECK_BIN:-}" && -x "$LUACHECK_BIN" ]]; then
    printf '%s\n' "$LUACHECK_BIN"
    return 0
  fi

  if [[ -x "$LUACHECK_COMMAND" ]]; then
    printf '%s\n' "$LUACHECK_COMMAND"
    return 0
  fi

  if command -v luacheck-fivem >/dev/null 2>&1; then
    command -v luacheck-fivem
    return 0
  fi

  return 1
}

install_luacheck() {
  if ! command -v luarocks >/dev/null 2>&1 || ! command -v git >/dev/null 2>&1; then
    if ! command -v apt-get >/dev/null 2>&1; then
      die "LuaRocks and git are required. Install Lua 5.3, LuaRocks, and git for your Linux distribution, then rerun this command."
    fi

    local apt_prefix=()
    if [[ "$(id -u)" -ne 0 ]]; then
      command -v sudo >/dev/null 2>&1 || die "sudo is required to install Lua, LuaRocks, and git"
      apt_prefix=(sudo)
    fi
    "${apt_prefix[@]}" apt-get update
    "${apt_prefix[@]}" apt-get install -y lua5.3 luarocks git
  fi

  mkdir -p "$CACHE_DIR"
  if [[ ! -d "$LUACHECK_SOURCE_DIR/.git" ]]; then
    echo "Cloning $LUACHECK_REPOSITORY@$LUACHECK_BRANCH"
    git clone --depth 1 --branch "$LUACHECK_BRANCH" \
      "https://github.com/$LUACHECK_REPOSITORY.git" "$LUACHECK_SOURCE_DIR"
  else
    echo "Updating $LUACHECK_REPOSITORY@$LUACHECK_BRANCH"
    git -C "$LUACHECK_SOURCE_DIR" fetch --depth 1 origin "$LUACHECK_BRANCH"
    git -C "$LUACHECK_SOURCE_DIR" checkout --detach FETCH_HEAD
  fi

  echo "Installing LuaCheck from $LUACHECK_REPOSITORY@$LUACHECK_BRANCH"
  (cd "$LUACHECK_SOURCE_DIR" && luarocks --tree "$LUACHECK_TREE" make)
  [[ -x "$LUACHECK_TREE/bin/luacheck" ]] || die "LuaRocks did not install LuaCheck in $LUACHECK_TREE/bin"
  mkdir -p "$(dirname "$LUACHECK_COMMAND")"
  ln -sfn "$LUACHECK_TREE/bin/luacheck" "$LUACHECK_COMMAND"
  [[ -x "$LUACHECK_COMMAND" ]] || die "Could not create $LUACHECK_COMMAND"
  printf '%s\n' "$LUACHECK_REPOSITORY@$LUACHECK_BRANCH" > "$LUACHECK_INSTALL_MARKER"
  echo "LuaCheck installed as $LUACHECK_COMMAND from $LUACHECK_REPOSITORY@$LUACHECK_BRANCH"
}

managed_luacheck_ready() {
  [[ -x "$LUACHECK_COMMAND" ]] || return 1
  [[ -x "$LUACHECK_TREE/bin/luacheck" ]] || return 1
  [[ -f "$LUACHECK_INSTALL_MARKER" ]] || return 1
  grep -Fxq "$LUACHECK_REPOSITORY@$LUACHECK_BRANCH" "$LUACHECK_INSTALL_MARKER"
}

lint() {
  local extra_libs=""
  local update=true
  local config
  local luacheck
  local temporary_config=""
  local -a arguments=()

  while (($#)); do
    case "$1" in
      --extra-libs)
        (($# >= 2)) || die "--extra-libs requires a value"
        extra_libs="$2"
        shift 2
        ;;
      --no-update)
        update=false
        shift
        ;;
      -h|--help)
        usage
        return 0
        ;;
      *)
        arguments+=("$1")
        shift
        ;;
    esac
  done

  if [[ "$update" == true ]]; then
    ensure_cache
  else
    [[ -s "$(cache_file .luacheckrc.default)" ]] || die "cache is empty; run '$0 update' or omit --no-update"
  fi

  if [[ -z "${LUACHECK_BIN:-}" ]] && ! managed_luacheck_ready; then
    install_luacheck
  fi
  luacheck=$(find_luacheck || true)
  [[ -n "$luacheck" ]] || die "LuaCheck is not installed; run '$0 install'"
  config=$(cache_file .luacheckrc.default)

  if [[ -n "$extra_libs" ]]; then
    [[ "$extra_libs" =~ ^[[:alnum:]_.+\-]+$ ]] || die "--extra-libs may only contain letters, numbers, '.', '_', '-', and '+'"
    temporary_config=$(mktemp "${TMPDIR:-/tmp}/fivem-lua-lint.XXXXXX")
    trap 'rm -f "$temporary_config"' RETURN
    sed "s/%%EXTRA%%/+${extra_libs}/g" "$(cache_file .luacheckrc.generated.template)" > "$temporary_config"
    config="$temporary_config"
  fi

  if ((${#arguments[@]} == 0)); then
    arguments=(-t .)
  fi

  echo "Running LuaCheck with definitions from $CACHE_DIR"
  "$luacheck" --operators "+=" --default-config "$config" "${arguments[@]}"
}

command_name="lint"
if (($#)); then
  case "$1" in
    update|install|lint|help|--help|-h)
      command_name="$1"
      shift
      ;;
  esac
fi

case "$command_name" in
  update)
    (($# == 0)) || die "update does not accept arguments"
    update_cache
    ;;
  install)
    (($# == 0)) || die "install does not accept arguments"
    install_luacheck
    ;;
  lint)
    lint "$@"
    ;;
  help|--help|-h)
    usage
    ;;
esac
