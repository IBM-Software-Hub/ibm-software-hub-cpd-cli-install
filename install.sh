#!/usr/bin/env bash

set -Eeuo pipefail

# @Author: Jeffrey Chijioke-Uche, Ph.D, IBM Computer Scientist & Quantum Ambassador / Data & AI Research Scientist
# @Description: Helper to install, upgrade, or downgrade IBM Software Hub CLI (cpd-cli) to a specified version.
# @Date: 2025-12-10
# @LICENSE: Apache License 2.0
# @Company: IBM
#
# This script installs, upgrades, or downgrades IBM Software Hub CLI (cpd-cli)
# using the correct GitHub release endpoint for each supported Software Hub release.
#
# Important v5.3.0 rule:
#   Software Hub / CPD 5.3.0 maps to cpd-cli 14.3.0, but the GitHub release tag is:
#     v14.3.0_refresh_2
#
# Example:
#   https://github.com/IBM/cpd-cli/releases/download/v14.3.0_refresh_2/cpd-cli-linux-EE-14.3.0.tgz
#
# Important v5.3.1 Hotfix / Patch rule:
#   PATCH=HOTFIX. Software Hub / CPD 5.3.1 maps to cpd-cli 14.3.1.
#   For Hotfix 0, use the normal v14.3.1 release tag.
#   For Hotfix 2, 3, 4, or 5, use release tags v14.3.1.2 through v14.3.1.5
#   while keeping the archive filename at cpd-cli-<platform>-EE-14.3.1.tgz.
#
# Examples:
#   No Hotfix:
#     https://github.com/IBM/cpd-cli/releases/download/v14.3.1/cpd-cli-linux-EE-14.3.1.tgz
#   Hotfix 2:
#     HOT=2
#     export HOT="${HOT}"
#     https://github.com/IBM/cpd-cli/releases/download/v14.3.1.${HOT}/cpd-cli-linux-EE-14.3.1.tgz


#-------------------------------------------------------------
# Safe defaults in case swh_manager.sh does not define these.
#-------------------------------------------------------------
START_TIME="${START_TIME:-$(date +%s)}"
THIS_DAY="${THIS_DAY:-$(date)}"
OPERATION="${OPERATION:-IBM Software Hub CLI operation}"
CHOICE_CODE="${CHOICE_CODE:-200}"
LINER="${LINER:-============================================================}"


#-------------------------------------------------------------
# Load shared manager functions if present.
#-------------------------------------------------------------
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"

if [ -f "${SCRIPT_DIR}/swh_manager.sh" ]; then
  # shellcheck source=/dev/null
  source "${SCRIPT_DIR}/swh_manager.sh"
else
  echo "WARNING: ${SCRIPT_DIR}/swh_manager.sh not found. Continuing without shared header helpers." >&2
fi


#-------------------------------------------------------------
# Header selection.
#-------------------------------------------------------------
if ! command -v cpd-cli >/dev/null 2>&1; then
  if declare -F header_1 >/dev/null 2>&1; then
    header_1
  fi
else
  if declare -F header_0 >/dev/null 2>&1; then
    header_0
  fi
fi

echo


#-------------------------------------------------------------
# Print error helper.
#-------------------------------------------------------------
_error() {
  echo "ERROR: $*" >&2
}


#-------------------------------------------------------------
# Validate version format.
# Expected format: x.y.z
#-------------------------------------------------------------
_is_semver_triplet() {
  local version="${1:-}"
  [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}


#-------------------------------------------------------------
# Convert user input to lowercase without relying on Bash 4-only
# parameter expansion. This is more portable for older bash.
#-------------------------------------------------------------
_lower() {
  printf '%s' "${1:-}" | tr '[:upper:]' '[:lower:]'
}


#-------------------------------------------------------------
# Validate CPD / Software Hub 5.3.1 hotfix input.
# PATCH=HOTFIX. Supported selections are exactly those exposed
# in the user menu for 5.3.1 install/upgrade flows.
#-------------------------------------------------------------
_validate_cpd_531_hotfix() {
  local hotfix="${1:-}"

  case "$hotfix" in
    0|2|3|4|5)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}


#-------------------------------------------------------------
# Prompt helper for CPD / Software Hub 5.3.1 hotfix selection.
# The menu is intentionally written to stderr so command
# substitution captures only the selected numeric hotfix value.
#-------------------------------------------------------------
_prompt_for_cpd_531_hotfix() {
  local hotfix=""

  while :; do
    {
      echo "Which 5.3.1 Hotfix?"
      echo "0 for No Hotfix"
      echo "2 for Hotfix 2"
      echo "3 for Hotfix 3"
      echo "4 for Hotfix 4"
      echo "5 for Hotfix 5"
    } >&2

    read -r -p "Enter 0, 2, 3, 4, or 5: " hotfix

    if _validate_cpd_531_hotfix "$hotfix"; then
      printf '%s\n' "$hotfix"
      return 0
    fi

    echo "Invalid hotfix selection. Please enter 0, 2, 3, 4, or 5." >&2
  done
}


#-------------------------------------------------------------
# Return a 5.3.1 hotfix selection only for install/upgrade flows.
# Downgrade and all other versions keep the existing flow and use
# normal release URL behavior.
#-------------------------------------------------------------
_get_cpd_531_hotfix_for_action() {
  local target_swh="${1:-}"
  local action="${2:-}"

  if [ "$target_swh" = "5.3.1" ] && { [ "$action" = "install" ] || [ "$action" = "upgrade" ]; }; then
    _prompt_for_cpd_531_hotfix
  else
    printf '0\n'
  fi
}


#-------------------------------------------------------------
# Map Software Hub / CPD release version to cpd-cli version.
#
# Input:
#   target_swh: x.y.z, for example 5.3.0
#
# Output:
#   cpd-cli version printed to stdout, for example 14.3.0
#-------------------------------------------------------------
_map_swh_to_cpd_cli_version() {
  local target_swh="$1"

  if ! _is_semver_triplet "$target_swh"; then
    _error "invalid SWH version '${target_swh}'. Expected x.y.z."
    return 1
  fi

  local major_minor patch cli_major cli_minor
  major_minor="${target_swh%.*}"
  patch="${target_swh##*.}"

  case "$major_minor" in
    5.3)
      # Software Hub 5.3.x -> cpd-cli 14.3.x
      cli_major=14
      cli_minor=3
      ;;
    5.2)
      # Software Hub 5.2.x -> cpd-cli 14.2.x
      cli_major=14
      cli_minor=2
      ;;
    5.1)
      # Software Hub 5.1.x -> cpd-cli 14.1.x
      cli_major=14
      cli_minor=1
      ;;
    5.0)
      # Software Hub 5.0.x -> cpd-cli 14.0.x
      cli_major=14
      cli_minor=0
      ;;
    4.8)
      cli_major=13
      cli_minor=1
      ;;
    4.7)
      cli_major=13
      cli_minor=0
      ;;
    4.6)
      cli_major=12
      cli_minor=0
      ;;
    4.5)
      cli_major=11
      cli_minor=0
      ;;
    4.0)
      cli_major=10
      cli_minor=0
      ;;
    3.5)
      cli_major=3
      cli_minor=5
      ;;
    3.0)
      cli_major=3
      cli_minor=0
      ;;
    *)
      _error "unsupported SWH version '${major_minor}' for automatic CLI mapping."
      _error "Please update _map_swh_to_cpd_cli_version()."
      return 1
      ;;
  esac

  printf '%s.%s.%s\n' "$cli_major" "$cli_minor" "$patch"
}


#-------------------------------------------------------------
# Detect target platform for the cpd-cli archive name.
#
# Output examples:
#   linux
#   darwin
#   s390x
#   ppc64le
#-------------------------------------------------------------
_detect_cpd_cli_platform() {
  local uname_s uname_m
  uname_s="$(uname -s)"
  uname_m="$(uname -m)"

  case "$uname_s" in
    Darwin)
      printf 'darwin\n'
      ;;
    Linux)
      case "$uname_m" in
        x86_64|amd64)
          printf 'linux\n'
          ;;
        s390x)
          printf 's390x\n'
          ;;
        ppc64le)
          printf 'ppc64le\n'
          ;;
        *)
          _error "unsupported Linux architecture '${uname_m}'."
          return 1
          ;;
      esac
      ;;
    *)
      _error "unsupported operating system '${uname_s}'."
      return 1
      ;;
  esac
}


#-------------------------------------------------------------
# Build cpd-cli download URL.
#
# Inputs:
#   target_swh:   Software Hub / CPD version, for example 5.3.0
#   cli_version:  cpd-cli version, for example 14.3.0
#   archive:      archive filename, for example cpd-cli-linux-EE-14.3.0.tgz
#   hotfix:       5.3.1 hotfix selector: 0, 2, 3, 4, or 5
#
# v5.3.0 special case:
#   target_swh 5.3.0 maps to cpd-cli 14.3.0 and uses GitHub tag:
#   v14.3.0_refresh_2
#
# v5.3.1 hotfix special case:
#   target_swh 5.3.1 maps to cpd-cli 14.3.1.
#   hotfix 0 uses tag v14.3.1.
#   hotfix 2-5 use tags v14.3.1.2 through v14.3.1.5,
#   while the archive filename remains cpd-cli-<platform>-EE-14.3.1.tgz.
#-------------------------------------------------------------
_build_cpd_cli_url() {
  local target_swh="$1"
  local cli_version="$2"
  local archive="$3"
  local hotfix="${4:-0}"

  case "$target_swh" in
    5.3.0)
      printf 'https://github.com/IBM/cpd-cli/releases/download/v%s_refresh_2/%s\n' \
        "$cli_version" "$archive"
      ;;
    5.3.1)
      if [ "$hotfix" != "0" ]; then
        printf 'https://github.com/IBM/cpd-cli/releases/download/v%s.%s/%s\n' \
          "$cli_version" "$hotfix" "$archive"
      else
        printf 'https://github.com/IBM/cpd-cli/releases/download/v%s/%s\n' \
          "$cli_version" "$archive"
      fi
      ;;
    *)
      printf 'https://github.com/IBM/cpd-cli/releases/download/v%s/%s\n' \
        "$cli_version" "$archive"
      ;;
  esac
}


#-------------------------------------------------------------
# Download file using curl or wget.
#-------------------------------------------------------------
_download_file() {
  local url="$1"
  local output_path="$2"

  if command -v curl >/dev/null 2>&1; then
    echo "Downloading with curl..."
    curl \
      --fail \
      --location \
      --retry 3 \
      --retry-delay 2 \
      --connect-timeout 20 \
      --output "$output_path" \
      "$url"
  elif command -v wget >/dev/null 2>&1; then
    echo "Downloading with wget..."
    wget \
      --tries=3 \
      --timeout=30 \
      --output-document="$output_path" \
      "$url"
  else
    _error "neither curl nor wget is installed; cannot download cpd-cli."
    return 1
  fi
}


#-------------------------------------------------------------
# Internal worker: install a specific SWH CLI / cpd-cli version.
#
# Usage:
#   _swh_cli_install_engine <target_swh_version> <action>
#
# Arguments:
#   target_swh_version: x.y.z, for example 5.3.0
#   action:             install | upgrade | downgrade
#-------------------------------------------------------------
_swh_cli_install_engine() {
  local target_swh="${1:-}"
  local action="${2:-}"
  local hotfix="${3:-0}"

  if ! _is_semver_triplet "$target_swh"; then
    _error "invalid SWH version '${target_swh}'. Expected x.y.z."
    return 1
  fi

  case "$action" in
    install|upgrade|downgrade)
      ;;
    *)
      _error "invalid action '${action}'. Expected install, upgrade, or downgrade."
      return 1
      ;;
  esac

  if [ "$target_swh" = "5.3.1" ]; then
    if ! _validate_cpd_531_hotfix "$hotfix"; then
      _error "invalid CPD 5.3.1 hotfix '${hotfix}'. Expected 0, 2, 3, 4, or 5."
      return 1
    fi

    if [ "$action" = "downgrade" ] && [ "$hotfix" != "0" ]; then
      _error "CPD 5.3.1 hotfix selection is supported for install and upgrade actions only."
      return 1
    fi

    HOT="$hotfix"
    export HOT
  elif [ "$hotfix" != "0" ]; then
    _error "hotfix selection applies only to SWH / CPD release 5.3.1."
    return 1
  fi

  local SUDO=""
  if [ "$(id -u)" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then
      SUDO="sudo"
    else
      _error "this operation requires root privileges or sudo."
      return 1
    fi
  fi

  local cli_version
  cli_version="$(_map_swh_to_cpd_cli_version "$target_swh")"

  echo "Target SWH CLI release: v${target_swh}"
  echo "Derived cpd-cli package version: ${cli_version}"

  if [ "$target_swh" = "5.3.1" ]; then
    if [ "${HOT}" = "0" ]; then
      echo "Selected CPD 5.3.1 Hotfix/Patch: 0 (No Hotfix)"
    else
      echo "Selected CPD 5.3.1 Hotfix/Patch: ${HOT}"
    fi
  fi

  local platform edition archive url
  platform="$(_detect_cpd_cli_platform)"
  edition="EE"
  archive="cpd-cli-${platform}-${edition}-${cli_version}.tgz"
  url="$(_build_cpd_cli_url "$target_swh" "$cli_version" "$archive" "$hotfix")"

  echo "Detected platform: ${platform}"
  echo "Selected edition: ${edition}"
  echo "Archive name: ${archive}"
  echo "Download URL will be: ${url}"

  local dest_dir
  dest_dir="/usr/local/bin"

  if [ ! -d "$dest_dir" ]; then
    _error "destination directory ${dest_dir} does not exist."
    return 1
  fi

  local tmpdir archive_path new_cli new_root
  tmpdir="$(mktemp -d 2>/dev/null || mktemp -d -t 'cpd-cli-install')"
  archive_path="${tmpdir}/${archive}"

  cleanup_tmpdir() {
    if [ -n "${tmpdir:-}" ] && [ -d "$tmpdir" ]; then
      rm -rf "$tmpdir"
    fi
  }
  trap cleanup_tmpdir RETURN

  echo "Using temporary directory: ${tmpdir}"

  if ! _download_file "$url" "$archive_path"; then
    _error "download failed from ${url}"
    return 1
  fi

  echo "Extracting ${archive_path}..."
  if ! tar -xzf "$archive_path" -C "$tmpdir"; then
    _error "failed to extract ${archive_path}"
    return 1
  fi

  new_cli="$(find "$tmpdir" -maxdepth 3 -type f -name 'cpd-cli' -print -quit)"

  if [ -z "$new_cli" ]; then
    _error "could not locate extracted cpd-cli binary in ${tmpdir}."
    return 1
  fi

  if [ ! -x "$new_cli" ]; then
    chmod +x "$new_cli" || true
  fi

  if [ ! -x "$new_cli" ]; then
    _error "extracted cpd-cli exists but is not executable: ${new_cli}"
    return 1
  fi

  new_root="$(dirname "$new_cli")"
  echo "Located new cpd-cli in: ${new_root}"

  echo "Performing ${action} of cpd-cli in ${dest_dir}."

  # Remove previous install artifacts.
  if ! $SUDO rm -rf \
    "${dest_dir}/cpd-cli" \
    "${dest_dir}/plugins" \
    "${dest_dir}/LICENSES"; then
    _error "failed to remove existing cpd-cli files from ${dest_dir}."
    return 1
  fi

  # Install cpd-cli binary.
  if ! $SUDO install -m 0755 "${new_root}/cpd-cli" "${dest_dir}/cpd-cli"; then
    _error "failed to install cpd-cli to ${dest_dir}."
    return 1
  fi

  # Install plugins if present.
  if [ -d "${new_root}/plugins" ]; then
    if ! $SUDO cp -a "${new_root}/plugins" "${dest_dir}/plugins"; then
      _error "failed to copy plugins directory to ${dest_dir}."
      return 1
    fi
  fi

  # Install LICENSES if present.
  if [ -e "${new_root}/LICENSES" ]; then
    if ! $SUDO cp -a "${new_root}/LICENSES" "${dest_dir}/LICENSES"; then
      _error "failed to copy LICENSES to ${dest_dir}."
      return 1
    fi
  fi

  # Refresh shell command cache.
  hash -r || true

  echo
  echo "${action} complete. New cpd-cli version:"
  "${dest_dir}/cpd-cli" version || true
}


#-------------------------------------------------------------
# Prompt helper for target SWH version.
#-------------------------------------------------------------
_prompt_for_swh_version() {
  local prompt_text="$1"
  local target_swh=""

  while :; do
    read -r -p "$prompt_text" target_swh

    if _is_semver_triplet "$target_swh"; then
      printf '%s\n' "$target_swh"
      return 0
    fi

    echo "Invalid version format. Please use x.y.z, for example 5.3.0 or 5.3.1."
  done
}


#-------------------------------------------------------------
# Public helper: install_swh_cli
#
# If cpd-cli is installed:
#   Ask user whether to upgrade or downgrade.
#
# If cpd-cli is not installed:
#   Ask user which SWH version to install.
#-------------------------------------------------------------
install_swh_cli() {
  local has_cpd_cli=0

  if command -v cpd-cli >/dev/null 2>&1; then
    has_cpd_cli=1
  fi

  if (( has_cpd_cli == 1 )); then
    echo "✅ Detected existing IBM SWH / CPD cpd-cli installation on this workstation."

    local checker
    checker="$(cpd-cli version 2>/dev/null || true)"

    if [ -n "$checker" ]; then
      local current_swh current_cli
      current_swh="$(printf '%s\n' "$checker" | awk -F': ' '/SWH Release Version|CPD Release Version/ {print $2; exit}')"
      current_cli="$(printf '%s\n' "$checker" | awk -F': ' '/^Version/ {print $2; exit}')"

      if [ -n "$current_swh" ]; then
        echo "✅ Current SWH / CPD CLI release version: v${current_swh}"
      fi

      if [ -n "$current_cli" ]; then
        echo "✅ Current cpd-cli operand version: ${current_cli}"
      fi
    else
      echo "⚠️ WARNING: could not retrieve cpd-cli version information."
    fi

    local choice action
    while :; do
      echo "🧾 Menu: [u] Upgrade cpd-cli to a different SWH release | [d] Downgrade cpd-cli to a different SWH release | [c] Cancel"
      read -r -p "🗣️ Do you want to Upgrade, Downgrade, or Cancel? [u/d/c]: " choice
      choice="$(_lower "$choice")"

      case "$choice" in
        u|upgrade)
          action="upgrade"
          break
          ;;
        d|downgrade)
          action="downgrade"
          break
          ;;
        c|cancel|"")
          echo "✅ Operation cancelled by user."
          echo "✅ Goodbye!"
          echo "🏦 IBM Corporation, All Rights Reserved (c) $(date +%Y)."
          echo "$LINER"
          return 0
          ;;
        *)
          echo "⚠️ Invalid choice. Please enter 'u' for upgrade, 'd' for downgrade, or 'c' to cancel."
          ;;
      esac
    done

    local target_swh hotfix
    target_swh="$(_prompt_for_swh_version "Enter target SWH / CPD CLI release version you need, for example 5.3.0 or 5.3.1: ")"
    hotfix="$(_get_cpd_531_hotfix_for_action "$target_swh" "$action")"

    echo "You chose to ${action} cpd-cli to SWH / CPD release v${target_swh}."
    _swh_cli_install_engine "$target_swh" "$action" "$hotfix"

  else
    echo "cpd-cli is not currently installed on this workstation."
    echo "This helper will install IBM Software Hub CLI / CPD CLI for you."

    local target_swh hotfix
    target_swh="$(_prompt_for_swh_version "Enter SWH / CPD CLI release version you need, for example 5.3.0 or 5.3.1: ")"
    hotfix="$(_get_cpd_531_hotfix_for_action "$target_swh" "install")"

    _swh_cli_install_engine "$target_swh" "install" "$hotfix"
  fi
}


#-------------------------------------------------------------
# Main
#-------------------------------------------------------------
install_swh_cli


#-------------------------------------------------------------
# Summary
#-------------------------------------------------------------
STOP_TIME="$(date +%s)"
ELAPSED_TIME="$(( STOP_TIME - START_TIME ))"
ACTION_NOTATION="== SUMMARY =="

if [[ "${CHOICE_CODE:-}" == "200" ]]; then
  export START_TIME
  export ACTION_NOTATION
  export ELAPSED_TIME
  export STOP_TIME
  export THIS_DAY

  echo

  if (( ELAPSED_TIME < 60 )); then
    echo "✅ $ACTION_NOTATION"
    echo "✅ Total time taken for ${OPERATION}: ${ELAPSED_TIME} Seconds"
    echo "✅ ${OPERATION} date: $THIS_DAY"
  elif (( ELAPSED_TIME < 120 )); then
    echo "✅ $ACTION_NOTATION"
    printf "✅ Total time taken for ${OPERATION}: 1 minute:%02d seconds\n" "$(( ELAPSED_TIME - 60 ))"
    echo "✅ ${OPERATION} date: $THIS_DAY"
  else
    echo "✅ $ACTION_NOTATION"
    echo "✅ Total time taken for ${OPERATION}: $(( ELAPSED_TIME / 60 )) Minutes"
    echo "✅ ${OPERATION} date: $THIS_DAY"
  fi
else
  echo "✅ Type Determinant not recognized. Unable to provide summary."
fi

echo "$LINER"