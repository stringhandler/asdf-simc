#!/usr/bin/env bash

set -euo pipefail

GH_REPO="https://github.com/BlockstreamResearch/SimplicityHL"
TOOL_NAME="simc"
TOOL_TEST="simc --version"

fail() {
  echo -e "asdf-${TOOL_NAME}: $*"
  exit 1
}

curl_opts=(-fsSL)

if [ -n "${GITHUB_API_TOKEN:-}" ]; then
  curl_opts+=(-H "Authorization: token ${GITHUB_API_TOKEN}")
fi

sort_versions() {
  sed 'h; s/[+-]/./g; s/.p\([[:digit:]]\)/.z\1/; s/$/.z/; G; s/\n/ /' |
    LC_ALL=C sort -t. -k 1,1 -k 2,2n -k 3,3n -k 4,4n -k 5,5n | awk '{print $2}'
}

list_github_tags() {
  git ls-remote --tags --refs "${GH_REPO}" |
    grep -o 'refs/tags/simplicityhl-[0-9][^/]*' |
    sed 's|refs/tags/simplicityhl-||'
}

list_all_versions() {
  list_github_tags
}

get_platform() {
  local os
  os="$(uname -s)"
  case "$os" in
    Linux) echo "linux" ;;
    Darwin) echo "macos" ;;
    MINGW* | MSYS* | CYGWIN*) echo "windows" ;;
    *) echo "" ;;
  esac
}

get_arch() {
  local arch
  arch="$(uname -m)"
  case "$arch" in
    x86_64 | amd64) echo "x86_64" ;;
    aarch64 | arm64) echo "aarch64" ;;
    *) echo "" ;;
  esac
}

# Returns the asset filename for the current platform, or exits 1 if unsupported.
get_binary_asset_name() {
  local platform arch ext
  platform="$(get_platform)"
  arch="$(get_arch)"

  if [ -z "$platform" ] || [ -z "$arch" ]; then
    return 1
  fi

  if [ "$platform" = "windows" ]; then
    ext="zip"
  else
    ext="tar.gz"
  fi

  echo "simc-${platform}-${arch}.${ext}"
}

# Returns 0 (true) if we should use a prebuilt binary, 1 (false) if we should build from source.
use_prebuilt() {
  if [ "${ASDF_SIMC_BUILD_FROM_SOURCE:-0}" = "1" ] || [ "${ASDF_SIMC_BUILD_FROM_SOURCE:-}" = "true" ]; then
    return 1
  fi
  get_binary_asset_name >/dev/null 2>&1
}

download_release() {
  local version="$1"
  local download_path="$2"

  mkdir -p "${download_path}"

  if use_prebuilt; then
    local asset_name
    asset_name="$(get_binary_asset_name)"
    local url="${GH_REPO}/releases/download/simplicityhl-${version}/${asset_name}"
    local local_file="${download_path}/${asset_name}"

    echo "* Downloading ${TOOL_NAME} ${version} prebuilt binary (${asset_name})..."
    curl "${curl_opts[@]}" -o "${local_file}" "${url}" || fail "Could not download ${url}"

    if [[ "${asset_name}" == *.zip ]]; then
      unzip -q "${local_file}" -d "${download_path}"
    else
      tar -xzf "${local_file}" -C "${download_path}"
    fi
    rm -f "${local_file}"

    # Marker so install_version knows which mode was used
    touch "${download_path}/.prebuilt"
  else
    local source_url="${GH_REPO}/archive/refs/tags/simplicityhl-${version}.tar.gz"
    local local_file="${download_path}/${TOOL_NAME}-${version}.tar.gz"

    echo "* Downloading ${TOOL_NAME} ${version} source (set ASDF_SIMC_BUILD_FROM_SOURCE=0 to use prebuilt)..."
    curl "${curl_opts[@]}" -o "${local_file}" "${source_url}" || fail "Could not download ${source_url}"
    tar -xzf "${local_file}" -C "${download_path}" --strip-components=1
    rm -f "${local_file}"
  fi
}

install_version() {
  local install_type="$1"
  local version="$2"
  local install_path="$3"
  local download_path="${ASDF_DOWNLOAD_PATH}"

  if [ "$install_type" != "version" ]; then
    fail "asdf-${TOOL_NAME} supports release installs only"
  fi

  (
    local bin_install_path="${install_path}/bin"
    mkdir -p "${bin_install_path}"

    if [ -f "${download_path}/.prebuilt" ]; then
      echo "* Installing ${TOOL_NAME} ${version} from prebuilt binary..."

      # The binary may be at the root or inside a subdirectory of the archive
      local simc_binary
      simc_binary="$(find "${download_path}" -name "${TOOL_NAME}" -type f | head -1)"
      if [ -z "$simc_binary" ]; then
        fail "Could not find ${TOOL_NAME} binary in downloaded archive"
      fi

      cp "${simc_binary}" "${bin_install_path}/${TOOL_NAME}"
      chmod +x "${bin_install_path}/${TOOL_NAME}"
    else
      if ! command -v cargo &>/dev/null; then
        fail "cargo not found. Please install Rust (https://rustup.rs/) before installing ${TOOL_NAME}."
      fi

      echo "* Building ${TOOL_NAME} ${version} from source..."
      cd "${download_path}"
      cargo build --release 2>&1

      cp "${download_path}/target/release/${TOOL_NAME}" "${bin_install_path}/${TOOL_NAME}"
    fi

    echo "* Verifying install..."
    local tool_cmd
    tool_cmd="$(echo "${TOOL_TEST}" | cut -d' ' -f1)"
    test -x "${bin_install_path}/${tool_cmd}" || fail "Expected ${tool_cmd} to be executable"

    echo "* ${TOOL_NAME} ${version} installed successfully."
  ) || (
    rm -rf "${install_path}"
    fail "An error occurred while installing ${TOOL_NAME} ${version}."
  )
}
