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

download_release() {
  local version="$1"
  local filename="$2"
  local url="${GH_REPO}/archive/refs/tags/simplicityhl-${version}.tar.gz"

  echo "* Downloading ${TOOL_NAME} ${version} source..."
  curl "${curl_opts[@]}" -o "${filename}" "${url}" || fail "Could not download ${url}"
}

install_version() {
  local install_type="$1"
  local version="$2"
  local install_path="$3"

  if [ "$install_type" != "version" ]; then
    fail "asdf-${TOOL_NAME} supports release installs only"
  fi

  (
    local build_dir="${ASDF_DOWNLOAD_PATH}"
    local bin_install_path="${install_path}/bin"

    # Verify cargo is available
    if ! command -v cargo &>/dev/null; then
      fail "cargo not found. Please install Rust (https://rustup.rs/) before installing ${TOOL_NAME}."
    fi

    echo "* Building ${TOOL_NAME} ${version} from source..."
    cd "${build_dir}"
    cargo build --release 2>&1

    mkdir -p "${bin_install_path}"
    cp "${build_dir}/target/release/${TOOL_NAME}" "${bin_install_path}/${TOOL_NAME}"

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
