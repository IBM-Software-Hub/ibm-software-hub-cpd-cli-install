#!/usr/bin/env bash

set -Eeuo pipefail

# @Author: Jeffrey Chijioke-Uche, Ph.D, IBM Computer Scientist & Quantum Ambassador / Data & AI Research Scientist
# @Description: Helper to install, upgrade, or downgrade IBM Software Hub CLI (cpd-cli) to a specified version.
# @Date: 2025-12-10
# @LICENSE: Apache License 2.0
# @Company: IBM
#
# This function is based on and extends the original upgrade_swh_cli() implementation
# to support install, upgrade, and downgrade workflows in an interactive, production-safe
# manner.


#-------------------------------------------------------------
# Internal worker: install a specific SWH CLI / cpd-cli version
# Usage: _swh_cli_install_engine <target_swh_version> <action>
#   target_swh_version: x.y.z (SWH release)
#   action: "install" | "upgrade" | "downgrade"
#-------------------------------------------------------------

source "$(dirname "$0")/swh_manager.sh"  # for header and summary logic
header

echo
_swh_cli_install_engine() {
  local target_swh="$1"
  local action="$2"

  # Use sudo only if not root and sudo exists
  local SUDO=""
  if [ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
  fi

  # Map SWH version -> cpd-cli operand version (copied from upgrade-swh-cli.sh logic)
  local major_minor patch cli_version cli_major cli_minor
  major_minor="${target_swh%.*}"   # e.g. 5.2
  patch="${target_swh##*.}"        # e.g. 2

  case "$major_minor" in
    5.2) cli_major=14; cli_minor=2 ;;  # SWH 5.2.x → cpd-cli 14.2.x 
    5.1) cli_major=14; cli_minor=1 ;;
    5.0) cli_major=14; cli_minor=0 ;;
    4.8) cli_major=13; cli_minor=1 ;;
    4.7) cli_major=13; cli_minor=0 ;;
    4.6) cli_major=12; cli_minor=0 ;;
    4.5) cli_major=11; cli_minor=0 ;;
    4.0) cli_major=10; cli_minor=0 ;;
    3.5) cli_major=3;  cli_minor=5 ;;
    3.0) cli_major=3;  cli_minor=0 ;;
    *)
      echo "ERROR: unsupported SWH version '$major_minor' for automatic CLI mapping." >&2
      echo "Please update the mapping logic in _swh_cli_install_engine()." >&2
      return 1
      ;;
  esac
  cli_version="${cli_major}.${cli_minor}.${patch}"

  echo "Target SWH CLI release: v${target_swh}"
  echo "Derived cpd-cli package version: ${cli_version}"

  # Detect OS / architecture:
  local uname_s uname_m platform
  uname_s="$(uname -s)"
  uname_m="$(uname -m)"

  case "$uname_s" in
    Darwin)
      platform="darwin"
      ;;
    Linux)
      case "$uname_m" in
        x86_64|amd64)
          platform="linux"
          ;;
        s390x)
          platform="s390x"
          ;;
        ppc64le)
          platform="ppc64le"
          ;;
        *)
          echo "ERROR: unsupported Linux architecture '$uname_m'." >&2
          return 1
          ;;
      esac
      ;;
    *)
      echo "ERROR: unsupported operating system '$uname_s'." >&2
      return 1
      ;;
  esac

  # Always use Enterprise Edition (EE)
  local edition archive version_tag url
  edition="EE"
  archive="cpd-cli-${platform}-${edition}-${cli_version}.tgz"
  version_tag="v${cli_version}"
  url="https://github.com/IBM/cpd-cli/releases/download/${version_tag}/${archive}"

  echo "Download URL will be: ${url}"

  # Temporary work directory
  local tmpdir
  tmpdir="$(mktemp -d 2>/dev/null || mktemp -d -t 'cpd-cli-install')"
  echo "Using temporary directory: ${tmpdir}"

  # Download archive
  local archive_path
  archive_path="${tmpdir}/${archive}"

  if command -v curl >/dev/null 2>&1; then
    echo "Downloading with curl..."
    if ! curl -fL "$url" -o "$archive_path"; then
      echo "ERROR: download failed from ${url}" >&2
      rm -rf "$tmpdir"
      return 1
    fi
  elif command -v wget >/dev/null 2>&1; then
    echo "Downloading with wget..."
    if ! wget -O "$archive_path" "$url"; then
      echo "ERROR: download failed from ${url}" >&2
      rm -rf "$tmpdir"
      return 1
    fi
  else
    echo "ERROR: neither curl nor wget is installed; cannot download cpd-cli." >&2
    rm -rf "$tmpdir"
    return 1
  fi

  # Extract archive (LICENSES, cpd-cli, plugins in root of tarball) 
  echo "Extracting ${archive_path}..."
  if ! tar -xzf "$archive_path" -C "$tmpdir"; then
    echo "ERROR: failed to extract ${archive_path}" >&2
    rm -rf "$tmpdir"
    return 1
  fi

  # Find directory that contains the new cpd-cli binary
  local new_root
  new_root="$(find "$tmpdir" -maxdepth 2 -type f -name 'cpd-cli' -print | head -n1 | xargs dirname)"
  if [ -z "$new_root" ] || [ ! -x "$new_root/cpd-cli" ]; then
    echo "ERROR: could not locate extracted cpd-cli binary in ${tmpdir}" >&2
    rm -rf "$tmpdir"
    return 1
  fi
  echo "Located new cpd-cli in: ${new_root}"

  # Destination directory – as in original upgrade script
  local dest_dir="/usr/local/bin"
  if [ ! -d "$dest_dir" ]; then
    echo "ERROR: destination directory ${dest_dir} does not exist." >&2
    rm -rf "$tmpdir"
    return 1
  fi

  echo "Performing ${action} of cpd-cli in ${dest_dir} (you might be prompted for sudo)..."

  # Remove old LICENSES, plugins, cpd-cli if present:
  if [ -e "${dest_dir}/cpd-cli" ] || [ -d "${dest_dir}/plugins" ] || [ -e "${dest_dir}/LICENSES" ]; then
    if ! $SUDO rm -rf "${dest_dir}/cpd-cli" "${dest_dir}/plugins" "${dest_dir}/LICENSES"; then
      echo "ERROR: failed to remove existing cpd-cli files from ${dest_dir}" >&2
      rm -rf "$tmpdir"
      return 1
    fi
  fi

  # Install new ones:
  if ! $SUDO cp -p "${new_root}/cpd-cli" "${dest_dir}/"; then
    echo "ERROR: failed to copy cpd-cli to ${dest_dir}" >&2
    rm -rf "$tmpdir"
    return 1
  fi

  if [ -d "${new_root}/plugins" ]; then
    if ! $SUDO cp -pr "${new_root}/plugins" "${dest_dir}/"; then
      echo "ERROR: failed to copy plugins directory to ${dest_dir}" >&2
      rm -rf "$tmpdir"
      return 1
    fi
  fi

  if [ -e "${new_root}/LICENSES" ]; then
    if ! $SUDO cp -pr "${new_root}/LICENSES" "${dest_dir}/"; then
      echo "ERROR: failed to copy LICENSES to ${dest_dir}" >&2
      rm -rf "$tmpdir"
      return 1
    fi
  fi

  # Make sure the binary is executable
  if ! $SUDO chmod +x "${dest_dir}/cpd-cli"; then
    echo "WARNING: could not chmod +x ${dest_dir}/cpd-cli (check permissions)." >&2
  fi

  # Clean up temp dir
  rm -rf "$tmpdir"

  echo "${action^} complete. New cpd-cli version:"
  cpd-cli version || true
}

#-------------------------------------------------------------
# Public helper: install_swh_cli
# - If cpd-cli is installed:
#     Ask user: Upgrade or Downgrade, then ask for target SWH version and apply.
# - If cpd-cli is NOT installed:
#     Ask user which SWH version to install and apply.
#-------------------------------------------------------------
install_swh_cli() {
  local has_cpd_cli=0

  if command -v cpd-cli >/dev/null 2>&1; then
    has_cpd_cli=1
  fi

  if (( has_cpd_cli == 1 )); then
    echo "✅ Detected existing IBM SWH (cpd) cpd-cli installation on this workstation."

    # Get current cpd-cli version info
    local checker
    checker="$(cpd-cli version 2>/dev/null || true)"
    if [ -n "$checker" ]; then
      local current_swh current_cli
      current_swh="$(printf '%s\n' "$checker" | awk -F': ' '/SWH Release Version|CPD Release Version/ {print $2; exit}')"
      current_cli="$(printf '%s\n' "$checker" | awk -F': ' '/^Version/ {print $2; exit}')"

      if [ -n "$current_swh" ]; then
        echo "✅ Current SWH (cpd) CLI software hub (cpd) release version: v${current_swh}"
      fi
      if [ -n "$current_cli" ]; then
        echo "✅ Current cpd-cli operand version: ${current_cli}"
      fi
    else
      echo "⚠️ WARNING: could not retrieve cpd-cli version information."
    fi

    # Ask user: upgrade or downgrade
    local choice action
    while :; do
      echo "Menu: [u] Upgrade cpd-cli to a different SWH release | [d] Downgrade cpd-cli to a different SWH release | [c] Cancel operation"
      read -r -p "🗣️ Do you want to Upgrade, Downgrade, or Cancel? [u/d/c]: " choice
      choice="${choice,,}"  # to lowercase
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
          echo "⚠️ Invalid choice. Please enter 'u' (upgrade), 'd' (downgrade), or 'c' (cancel)."
          ;;
      esac
    done

    # Ask for target SWH CLI version
    local target_swh
    while :; do
      read -r -p "Enter target SWH (cpd) CLI software hub (cpd) release version you need (x.y.z, e.g. 5.2.2): " target_swh
      if printf '%s' "$target_swh" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
        break
      fi
      echo "Invalid version format. Please use x.y.z (for example 5.2.2)."
    done

    echo "You chose to ${action} cpd-cli to SWH release v${target_swh}."
    _swh_cli_install_engine "${target_swh}" "${action}"

  else
    echo "cpd-cli is not currently installed on this workstation."
    echo "This helper will install IBM Software Hub CLI (cpd-cli) for you."

    # Ask for target SWH CLI version to install
    local target_swh
    while :; do
      read -r -p "Enter SWH (cpd) CLI software hub (cpd) release version you need (x.y.z, e.g. 5.2.2): " target_swh
      if printf '%s' "$target_swh" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
        break
      fi
      echo "Invalid version format. Please use x.y.z (for example 5.2.2)."
    done

    _swh_cli_install_engine "${target_swh}" "install"
  fi
}
install_swh_cli


#----------------------------------------------------------------
# Summary: Check Type Determinant and print appropriate message:
#----------------------------------------------------------------
STOP_TIME=$(date +%s)
ELAPSED_TIME=$(( STOP_TIME - START_TIME ))
ACTION_NOTATION="== SUMMARY =="
if [[ "$CHOICE_CODE" -eq 200 ]]; then
   export START_TIME="$START_TIME"
   export ACTION_NOTATION="$ACTION_NOTATION"
   export ELAPSED_TIME="$ELAPSED_TIME"
   export STOP_TIME="$STOP_TIME"
   export THIS_DAY="$THIS_DAY"
  if (( ELAPSED_TIME < 60 )); then
    echo "✅ $ACTION_NOTATION"
    echo "✅ Total time taken for ${OPERATION}: ${ELAPSED_TIME} Seconds"
    echo "✅ ${OPERATION} date: $THIS_DAY"
  elif (( ELAPSED_TIME < 120 )); then
    echo "✅ $ACTION_NOTATION"
    printf "✅ Total time taken for ${OPERATION}: 1minute:%02dseconds\n" $(( ELAPSED_TIME - 60 ))
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