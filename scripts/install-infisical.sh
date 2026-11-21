#!/usr/bin/env bash
# Resolves and installs the Infisical CLI.
#
# Usage:
#   install-infisical.sh resolve   -> writes `version`, `arch` and `candidates` to $GITHUB_OUTPUT
#   install-infisical.sh install   -> installs into $INSTALL_DIR, writes `version` and `method`
#
# Infisical sometimes publishes a GitHub release before its binaries finish uploading
# (or with a broken asset). To avoid failing on those, `resolve` only keeps releases
# whose tarball for this runner's architecture is actually uploaded, and `install`
# validates each download (gzip integrity + `infisical --version`) and falls back to
# the previous release when one is unusable. If no release works, it falls back to apt.
#
# Environment:
#   GH_TOKEN        Token for the GitHub API (optional, avoids anonymous rate limits)
#   CANDIDATES      Space-separated release tags to try (install mode; from resolve)
#   MAX_CANDIDATES  How many valid releases to consider (default: 5)
#   INSTALL_DIR     Destination directory (default: .tools/infisical)
#   CACHE_KEY_PREFIX  Prefix for the `restore-keys` output (resolve mode)

set -uo pipefail

REPO="Infisical/cli"
MAX_CANDIDATES="${MAX_CANDIDATES:-5}"
INSTALL_DIR="${INSTALL_DIR:-.tools/infisical}"
GITHUB_OUTPUT="${GITHUB_OUTPUT:-/dev/stdout}"

detect_arch() {
  case "${RUNNER_ARCH:-$(uname -m)}" in
    X64 | x86_64 | amd64) echo "amd64" ;;
    ARM64 | aarch64 | arm64) echo "arm64" ;;
    X86 | i386 | i686) echo "386" ;;
    *)
      echo "❌ Unsupported runner architecture: ${RUNNER_ARCH:-$(uname -m)}" >&2
      return 1
      ;;
  esac
}

ARCH="$(detect_arch)" || exit 1

asset_name() {
  # $1 = tag (e.g. v0.45.13)
  echo "cli_${1#v}_linux_${ARCH}.tar.gz"
}

resolve() {
  echo "🔍 Looking for Infisical CLI releases with a linux_${ARCH} binary..."

  local auth=()
  if [[ -n "${GH_TOKEN:-}" ]]; then
    auth=(-H "Authorization: Bearer ${GH_TOKEN}")
  fi

  local json
  if ! json=$(curl -fsSL --proto "=https" --proto-redir "=https" --retry 3 --retry-delay 2 \
    -H "Accept: application/vnd.github+json" "${auth[@]}" \
    "https://api.github.com/repos/${REPO}/releases?per_page=30"); then
    echo "⚠️ Could not query the GitHub API for ${REPO} releases; will fall back to apt."
    {
      echo "arch=${ARCH}"
      echo "version="
      echo "candidates="
    } >>"$GITHUB_OUTPUT"
    return 0
  fi

  # Log releases that are skipped because the binary isn't there (yet).
  jq -r --arg arch "$ARCH" '
    .[]
    | select(.draft == false and .prerelease == false)
    | select(.tag_name | test("^v[0-9]+\\.[0-9]+\\.[0-9]+$"))
    | (.tag_name | ltrimstr("v")) as $v
    | select([.assets[] | select(.name == "cli_\($v)_linux_\($arch).tar.gz" and .state == "uploaded" and .size > 0)] | length == 0)
    | "⚠️ Skipping \(.tag_name): asset cli_\($v)_linux_\($arch).tar.gz is missing or not fully uploaded"
  ' <<<"$json" | head -n 5

  local candidates
  candidates=$(jq -r --arg arch "$ARCH" --argjson max "$MAX_CANDIDATES" '
    [ .[]
      | select(.draft == false and .prerelease == false)
      | select(.tag_name | test("^v[0-9]+\\.[0-9]+\\.[0-9]+$"))
      | (.tag_name | ltrimstr("v")) as $v
      | select(any(.assets[]; .name == "cli_\($v)_linux_\($arch).tar.gz" and .state == "uploaded" and .size > 0))
      | .tag_name
    ][:$max] | join(" ")
  ' <<<"$json")

  if [[ -z "$candidates" ]]; then
    echo "⚠️ No release with a valid linux_${ARCH} binary found; will fall back to apt."
  else
    echo "✅ Candidate releases (newest first): ${candidates}"
  fi

  local first="${candidates%% *}" tag
  {
    echo "arch=${ARCH}"
    echo "version=${first#v}"
    echo "candidates=${candidates}"
    # Older candidates' cache keys, so a binary cached after a fallback can be restored.
    echo "restore-keys<<EOF_RESTORE_KEYS"
    for tag in ${candidates#"$first"}; do
      echo "${CACHE_KEY_PREFIX:-}${tag#v}"
    done
    echo "EOF_RESTORE_KEYS"
  } >>"$GITHUB_OUTPUT"
}

place_binary() {
  # $1 = source binary, $2 = "mv" or "cp". Returns non-zero if it cannot be placed.
  local src="$1" op="$2"
  if ! rm -rf "$INSTALL_DIR" || ! mkdir -p "$INSTALL_DIR"; then
    echo "  ❌ Cannot create install directory ${INSTALL_DIR}"
    return 1
  fi
  if ! "$op" "$src" "${INSTALL_DIR}/infisical" || ! chmod +x "${INSTALL_DIR}/infisical"; then
    echo "  ❌ Cannot place the binary in ${INSTALL_DIR}"
    return 1
  fi
}

cached_version() {
  # Prints the version of a binary restored from cache into INSTALL_DIR, if any.
  local bin="${INSTALL_DIR}/infisical"
  [[ -x "$bin" ]] || return 1
  "$bin" --version 2>/dev/null | awk '{print $NF; exit}'
}

try_release() {
  # $1 = tag. Downloads, validates and installs the release binary. Returns non-zero on any failure.
  local tag="$1" asset url tmp
  asset="$(asset_name "$tag")"
  url="https://github.com/${REPO}/releases/download/${tag}/${asset}"
  tmp="$(mktemp -d)"

  echo "⬇️ Trying Infisical CLI ${tag#v} from ${url}"

  if ! curl -fsSL --proto "=https" --proto-redir "=https" --retry 3 --retry-delay 2 -o "${tmp}/${asset}" "$url"; then
    echo "  ⚠️ Download failed (HTTP error or network issue)"
    rm -rf "$tmp"
    return 1
  fi

  if ! gzip -t "${tmp}/${asset}" 2>/dev/null; then
    echo "  ⚠️ Downloaded file is not a valid gzip archive"
    rm -rf "$tmp"
    return 1
  fi

  mkdir -p "${tmp}/extract"
  if ! tar -xzf "${tmp}/${asset}" -C "${tmp}/extract"; then
    echo "  ⚠️ Failed to extract archive"
    rm -rf "$tmp"
    return 1
  fi

  local bin="${tmp}/extract/infisical"
  if [[ ! -f "$bin" ]]; then
    bin="$(find "${tmp}/extract" -type f -name infisical | head -n 1)"
  fi
  if [[ -z "$bin" || ! -f "$bin" ]]; then
    echo "  ⚠️ Archive does not contain an 'infisical' binary"
    rm -rf "$tmp"
    return 1
  fi

  chmod +x "$bin"
  local reported
  if ! reported=$("$bin" --version 2>&1); then
    echo "  ⚠️ Binary failed to run: ${reported}"
    rm -rf "$tmp"
    return 1
  fi

  if ! place_binary "$bin" mv; then
    rm -rf "$tmp"
    return 1
  fi
  rm -rf "$tmp"

  echo "  ✅ Installed: ${reported}"
  return 0
}

install_via_apt() {
  echo "📦 Falling back to the Infisical apt repository..."
  if ! curl -1sLf --proto '=https' --proto-redir '=https' 'https://artifacts-cli.infisical.com/setup.deb.sh' | sudo -E bash; then
    echo "❌ Failed to set up the Infisical apt repository"
    return 1
  fi
  sudo apt-get update -qq || true
  if ! sudo apt-get install -y infisical; then
    echo "❌ Failed to install Infisical CLI via apt"
    return 1
  fi

  # Use the executable owned by the package, not whatever comes first on PATH.
  local pkg_bin
  pkg_bin=$(dpkg -L infisical 2>/dev/null | grep -E '/bin/infisical$' | head -n 1)
  if [[ -z "$pkg_bin" || ! -x "$pkg_bin" ]]; then
    echo "❌ Could not locate the infisical executable installed by the apt package"
    return 1
  fi
  if ! place_binary "$pkg_bin" cp; then
    return 1
  fi

  local version
  version=$(dpkg-query -W -f='${Version}' infisical 2>/dev/null || true)
  echo "✅ Installed Infisical CLI ${version} via apt (${pkg_bin})"
  {
    echo "version=${version}"
    echo "method=apt"
  } >>"$GITHUB_OUTPUT"
}

install() {
  local tag attempted=0 cached
  cached="$(cached_version || true)"
  if [[ -n "$cached" ]]; then
    echo "ℹ️ Found cached Infisical CLI ${cached} (restored from a previous fallback)"
  fi

  for tag in ${CANDIDATES:-}; do
    attempted=$((attempted + 1))
    if [[ -n "$cached" && "${tag#v}" == "$cached" ]]; then
      echo "✅ Using cached Infisical CLI ${cached}; newer release(s) were unusable"
      {
        echo "version=${cached}"
        echo "method=cache"
      } >>"$GITHUB_OUTPUT"
      return 0
    fi
    if try_release "$tag"; then
      if [[ $attempted -gt 1 ]]; then
        echo "ℹ️ Fell back to ${tag} because newer release(s) were unusable"
      fi
      {
        echo "version=${tag#v}"
        echo "method=release"
      } >>"$GITHUB_OUTPUT"
      return 0
    fi
    echo "↩️ ${tag} is unusable, trying the previous release..."
  done

  install_via_apt
}

case "${1:-}" in
  resolve) resolve ;;
  install) install ;;
  *)
    echo "Usage: $0 {resolve|install}" >&2
    exit 2
    ;;
esac
