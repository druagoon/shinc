#!/usr/bin/env bash

# @describe Generate bash cli script using `argc` command written in bash
# @meta version 0.1.0
# @meta require-tools awk,sed,shfmt,yq
# @meta inherit-flag-options
# @flag -D --debug Enable debug mode

set -euo pipefail

OS="$(uname)"
if [[ "${OS}" == "Darwin" ]]; then
    SED="gsed"
    AWK="gawk"
elif [[ "${OS}" == "Linux" ]]; then
    SED="sed"
    AWK="awk"
else
    echo "Unsupported OS: ${OS}" >&2
    exit 1
fi

# Directories
SHINC_DIR="$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/.." && pwd)"
# Define the path to the AWK script used for shell inclusion.
# The script is located in the base directory and is named 'shinc.awk'.
SHINC_AWK="${SHINC_DIR}/share/awk/shinc.awk"

# Directories
PROJECT_DIR="$(pwd)"
CONFIG_DIR="${PROJECT_DIR}/.config/shinc"
CONFIG_FILE="${CONFIG_DIR}/config.toml"
CONTRIB_DIR="${PROJECT_DIR}/contrib"
COMP_DIR="${CONTRIB_DIR}/completions"
MAN_DIR="${CONTRIB_DIR}/man"
MAN1_DIR="${MAN_DIR}/man1"

# Project
NAME="$(yq -r '.project.name' "${CONFIG_FILE}")"
VERSION="$(yq -r '.project.version' "${CONFIG_FILE}")"
TAG="v${VERSION}"

# Sources
SRC_DIR="${PROJECT_DIR}/src"
SRC_MAIN="${SRC_DIR}/main.sh"
BUILD_DIR="${PROJECT_DIR}/build"
BUILD_TARGET="${BUILD_DIR}/${NAME}.sh"
BIN_DIR="${PROJECT_DIR}/bin"
BIN_TARGET="${BIN_DIR}/${NAME}"
DIST_DIR="${PROJECT_DIR}/dist"

# Tools
SHFMT_OPTS="-ln=auto -i 4 -ci -bn -w"

debug() {
    printf "\033[35m==>\033[0m \033[1m%s\033[0m\n" "$*"
}

hai() {
    printf "  \033[34m==>\033[0m \033[1m%s\033[0m\n" "$*"
}

ensure_dir() {
    for dir in "$@"; do
        if [[ ! -d "${dir}" ]]; then
            mkdir -p "${dir}"
        fi
    done
}

fmt_shell() {
    shfmt ${SHFMT_OPTS} "$@"
}

generate_completions() {
    mkdir -p "${COMP_DIR}"/{bash,fish,zsh}
    argc --argc-completions bash "${NAME}" >"${COMP_DIR}/bash/${NAME}"
    argc --argc-completions fish "${NAME}" >"${COMP_DIR}/fish/${NAME}.fish"
    local comp_zsh="${COMP_DIR}/zsh/_${NAME}"
    argc --argc-completions zsh "${NAME}" >"${comp_zsh}"
    # Detect and insert the `#compdef` line if it doesn't exist for zsh completions autoloading
    ${SED} -i '1{/^#compdef /!i\
#compdef argc '"${NAME}"'\n
}' "${comp_zsh}"
}

generate_man_pages() {
    argc --argc-mangen "${BUILD_TARGET}" "${MAN1_DIR}"
}

# @cmd Format shell scripts
fmt() {
    return
}

# @cmd Format shell scripts in `./src`
fmt::src() {
    fmt_shell "${SRC_DIR}"
}

# @cmd Format shell scripts in current directory
fmt::all() {
    fmt_shell .
}

# @cmd Compile and build binaries
build() {
    debug "Building ${NAME}"

    hai "Formatting sources: ${SRC_DIR}"
    fmt::src

    cd "${SRC_DIR}" || exit
    ensure_dir "${BUILD_DIR}" "${BIN_DIR}"
    hai "Compiling source: ${SRC_MAIN} -> ${BUILD_TARGET}"
    export shinc_args_version="${VERSION}"
    ${AWK} -f "${SHINC_AWK}" "${SRC_MAIN}" >"${BUILD_TARGET}"
    chmod +x "${BUILD_TARGET}"
    fmt_shell "${BUILD_TARGET}"

    hai "Argc build: ${BUILD_TARGET} -> ${BIN_TARGET}"
    argc --argc-build "${BUILD_TARGET}" "${BIN_TARGET}"
    fmt_shell "${BIN_TARGET}"
    chmod +x "${BIN_TARGET}"

    hai "Generate shell completions"
    generate_completions

    hai "Generate man pages"
    generate_man_pages
}

# @cmd Test binaries
test() {
    debug "Testing ${NAME}"

    ${BIN_TARGET} --version
}

# @cmd Release (bump version, update CHANGELOG, create a tag, push to remote)
#
# Examples:
#   shinc release 1.0.0
#   shinc release 1.0.0 --no-commit
#   shinc release 1.0.0 --no-tag
#   shinc release 1.0.0 --no-push
#
# @meta require-tools git,git-cliff
# @flag      --no-commit                            Do not commit changes
# @flag      --no-tag                               Do not create a tag
# @flag      --no-push                              Do not push to remote repository
# @option    --remote-repository=origin <NAME>      Remote repository name
# @arg version!                                     Version number
release() {
    debug "Releasing ${NAME}"

    local version="${argc_version:-}"
    if [[ ! "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Invalid version: ${version}" >&2
        exit 1
    fi

    local tag="v${version}"
    if git rev-parse "${tag}" >/dev/null 2>&1; then
        echo "tag already exists: ${tag}" >&2
        exit 1
    fi

    local answer choice
    read -p "Release ${NAME} ${version} [y/N]: " choice
    answer="${choice:-n}"
    if [[ "${answer@L}" != "y" ]]; then
        exit
    fi

    local branch="$(git branch --show-current)"
    read -p "Confirm branch: ${branch} [y/N]: " choice
    answer="${choice:-n}"
    if [[ "${answer@L}" != "y" ]]; then
        exit
    fi

    hai "Version: ${version}"
    hai "Tag: ${tag}"

    hai "Update version"
    ${SED} -i -E \
        -e 's/^version = "[0-9]+\.[0-9]+\.[0-9]+"$/version = "'"${version}"'"/' \
        "${CONFIG_FILE}"
    git add "${CONFIG_FILE}"
    ${SED} -i -E \
        -e 's/^(# @meta version )[0-9]+\.[0-9]+\.[0-9]+$/\1'"${version}"'/' \
        "${SRC_MAIN}"
    git add "${SRC_MAIN}"

    hai "Update CHANGELOG"
    local changelog="CHANGELOG.md"
    git cliff -o "${changelog}" -t "${tag}"
    git add "${changelog}"

    if [[ "${argc_no_commit:-}" == "1" ]]; then
        exit
    fi
    hai "Commit changes"
    git commit -m "chore: Release ${NAME} ${version}"

    if [[ "${argc_no_tag:-}" == "1" ]]; then
        exit
    fi
    hai "Create tag"
    git tag -a -m "chore: Release ${NAME} ${version}" "${tag}"

    if [[ "${argc_no_push:-}" == "1" ]]; then
        exit
    fi
    hai "Push to remote repository"
    git push "${argc_remote_repository:-origin}" "${branch}"
    git push "${argc_remote_repository:-origin}" "${tag}"
}

# @cmd Distribute binaries
dist() {
    debug "Distributing ${NAME}"

    if [[ ! -f ${BIN_TARGET} ]]; then
        echo "Binary not found: ${BIN_TARGET}" >&2
        exit 1
    fi

    ensure_dir "${DIST_DIR}"
    local name="${NAME}-${TAG}.tar.gz"
    local fullname="${DIST_DIR}/${name}"
    hai "Archive to: ${fullname}"
    local -a include_files
    readarray -t include_files < <(yq -r '.project.include[]' "${CONFIG_FILE}")
    if [[ "${#include_files[@]}" -eq 0 ]]; then
        include_files=(
            bin
            contrib
            include
            LICENSE
            README.md
        )
    fi

    local -a archive_files
    for file in "${include_files[@]}"; do
        if [[ -e "${PROJECT_DIR}/${file}" ]]; then
            archive_files+=("${file}")
        fi
    done
    tar -cvzf "${fullname}" "${archive_files[@]}"

    local checksum="${DIST_DIR}/${name}.sha256"
    hai "Generate sha256sum: ${checksum}"
    cd "${DIST_DIR}" && sha256sum "${name}" >"${checksum}"
}

# @cmd Clean up
clean() {
    debug "Clean up"

    local -a dirs=(
        "${BIN_DIR}"
        "${BUILD_DIR}"
        "${CONTRIB_DIR}"
        "${DIST_DIR}"
    )
    rm -rf "${dirs[@]}"
}

# Hooks
_argc_before() {
    if [[ "${argc_debug:-}" == "1" ]]; then
        set -x
    fi
}
