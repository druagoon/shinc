#!/usr/bin/env bash

# @describe Generate bash cli script using `argc` command written in bash
# @meta inherit-flag-options
# @flag -D --debug Enable debug mode

set -e
set -o pipefail

BASE_DIR="${ARGC_PWD}"
TEMP_DIR="${BASE_DIR}/tmp"
TEMP_SRC_DIR="${TEMP_DIR}/src"
TEMP_BIN_DIR="${TEMP_DIR}/bin"

# @cmd TOML files tools
# @meta require-tools taplo
toml() {
    return
}

# @cmd Format all TOML files
toml::format() {
    taplo format
}

# @cmd Check all TOML files
toml::check() {
    taplo format --check
}

# @cmd Compile and build binaries
# @meta require-tools argc
build() {
    mkdir -p "${TEMP_SRC_DIR}" "${TEMP_BIN_DIR}"
    cp -a ./share "${TEMP_DIR}"
    cp ./src/main.sh "${TEMP_SRC_DIR}"/shinc.sh
    argc --argc-build "${TEMP_SRC_DIR}"/shinc.sh "${TEMP_BIN_DIR}"/shinc
    "${TEMP_BIN_DIR}"/shinc build
    rm -rf "${TEMP_DIR}"
}

# Hooks
_argc_before() {
    if [[ "${argc_debug}" == "1" ]]; then
        set -x
    fi
}

# See more details at https://github.com/sigoden/argc
eval "$(argc --argc-eval "$0" "$@")"
