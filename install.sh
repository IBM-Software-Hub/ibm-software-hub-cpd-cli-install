#!/usr/bin/env bash

set -Eeuo pipefail
#---------------------------------------------------------------------------------------------------------------------
#                                 CLOUD PAK FOR DATA CLI INSTALLATION
#---------------------------------------------------------------------------------------------------------------------
# @Author: Dr. Jeffrey Chijioke-Uche
# @Usage:  Install cpd-cli

#################################################
# Permissions & Sourcing
#################################################
chmod 777 license_accept.sh

# Use "." instead of "source" for broader shell compatibility if needed
. ./license_accept.sh


##############################################################  
# Discover the directory that holds the current cpd-cli on PATH
##############################################################
discover_cli_bin() {
  local cpd_bin
  cpd_bin="$(command -v cpd-cli || true)" || true
  if [ -z "$cpd_bin" ]; then
    echo "Friendly Notice: cpd-cli not found on PATH. We need installation." >&2
    return 0
  fi

  # Resolve symlinks if possible
  if command -v readlink >/dev/null 2>&1; then
    cpd_bin="$(readlink -f "$cpd_bin" 2>/dev/null || echo "$cpd_bin")"
    return 0
  fi

  # If INSTALL dir is found, export it  else leave it unset for later use
  if [ -d "$(dirname "$cpd_bin")" ]; then
    echo "Friendly Notice: cpd-cli found at: $cpd_bin" >&2
  else
    echo "Friendly Notice: cpd-cli path could not be resolved." >&2
    return 0
  fi
  export INSTALL_DIR="$(dirname "$cpd_bin")"
  echo "INSTALL_DIR set to: $INSTALL_DIR"
  
}
discover_cli_bin
 

#################################################
# Reset function
#################################################
# Delete cpd-cli (file), plugins (dir), LICENSES (dir) from $INSTALL_DIR
cli_reset() {
  local dir="${INSTALL_DIR:-}"

  # sanity checks: If 
  if [ -z "$dir" ]; then
    echo "NOTICE: INSTALL_DIR is not set." >&2
    return 0
  fi
  case "$dir" in
    "/"|"") echo "ERROR: Refusing to operate on '$dir'." >&2; return 2 ;;
  esac

  # helper: run command, fallback to sudo if needed
  _try() { "$@" 2>/dev/null || { command -v sudo >/dev/null && sudo "$@"; }; }

  # clear immutable attr (if present) then remove
  _zap() {
    local p="$1"
    if [ -e "$p" ] || [ -L "$p" ]; then
      command -v chattr >/dev/null 2>&1 && _try chattr -R -i "$p" || true
      if [ -d "$p" ] && [ ! -L "$p" ]; then
        _try rm -rf -- "$p" && echo "Removed directory: $p" || echo "FAILED to remove: $p"
      else
        _try rm -f -- "$p" && echo "Removed file/link:  $p" || echo "FAILED to remove: $p"
      fi
    else
      echo "Not found (skipped): $p"
    fi
  }

  echo "Cleaning install targets under: $dir"
  _zap "$dir/cpd-cli"      # file
  _zap "$dir/plugins"      # directory
  _zap "$dir/LICENSES"     # directory
}
cli_reset


################################################
# User OS selection
################################################
USER_OS() {
  # Pretty table renderer
  _print_menu() {
    echo
    echo "+----+----------------------------------------------+"
    printf "| %-2s | %-44s |\n" "ID" "Operating System"
    echo "+----+----------------------------------------------+"
    printf "| %-2s | %-44s |\n" "0" "Quit"
    printf "| %-2s | %-44s |\n" "1" "Linux"
    printf "| %-2s | %-44s |\n" "2" "Mac OS"
    printf "| %-2s | %-44s |\n" "3" "Windows (Windows Subsystem for Linux)"
    printf "| %-2s | %-44s |\n" "4" "POWER (ppc64le)"
    printf "| %-2s | %-44s |\n" "5" "Z (s390x)"
    echo "+----+----------------------------------------------+"
    echo
  }

  # If already set, keep it (comment these two lines out if you want to force selection every time)
  if [[ -n "${OS_ARCHITECTURE:-}" ]]; then
    echo "OS_ARCHITECTURE already set to '${OS_ARCHITECTURE}'."
    return 0
  fi

  while :; do
    _print_menu
    read -rp "Please enter an ID [0-5]: " choice

    case "$choice" in
      0)
        echo "You selected to quit installation, Goodbye!"
        exit 0
        ;;
      1)
        echo "You selected linux OS"
        OS_ARCHITECTURE="linux-EE"
        export OS_ARCHITECTURE
        break
        ;;
      2)
        echo "You selected Mac OS"
        OS_ARCHITECTURE="darwin-EE"
        export OS_ARCHITECTURE
        break
        ;;
      3)
        echo "You selected Windows Subsystem for Linux OS"
        OS_ARCHITECTURE="linux-EE"
        export OS_ARCHITECTURE
        break
        ;;
      4)
        echo "You selected Power OS"
        OS_ARCHITECTURE="ppc64le-EE"
        export OS_ARCHITECTURE
        break
        ;;
      5)
        echo "You selected zOS"
        OS_ARCHITECTURE="s390x-EE"
        export OS_ARCHITECTURE
        break
        ;;
      *)
        echo "Invalid selection. Please enter a number from 0 to 5."
        ;;
    esac
  done

  echo "OS Architecture: ${OS_ARCHITECTURE}"
}
USER_OS


#################################################
CPD_INSTALLER_OBJECTS() {
  # Directory where THIS script lives
  local here vars_sh vars_d
  here="$(cd -- "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

  vars_sh="${here}/vars.sh"
  vars_d="${here}/vars.d"   # must exist

  # 1) vars.d must exist (file)
  if [[ ! -f "$vars_d" ]]; then
    echo "ERROR: Required 'vars.d' not found at: $vars_d"
    exit 1
  fi

  # 2) If vars.sh exists, check placeholder token
  if [[ -f "$vars_sh" ]]; then
    chmod +x "$vars_sh" 2>/dev/null || true
    . ./vars.sh
    if grep -qi -- '<!---provide' "$vars_sh"; then
      echo "Please provide the missing value of the variables in vars.sh"
      exit 0
    fi
    # clean -> continue
    return 0
  fi

  # 3) vars.sh missing -> copy vars.d -> vars.sh (do NOT delete vars.d)
  if [[ ! -f "$vars_sh" ]]; then
    echo "vars.sh not found. Creating from vars.d template....."
    sleep 3
    cp -f -- "$vars_d" "$vars_sh"
    chmod +x "$vars_sh" 2>/dev/null || true
    source ./vars.sh
    echo "Please provide the missing value of the variables in vars.sh"
    exit 0
  fi

  # If vars.sh exists and no placeholder, we're good, source vars.sh and move on:
  chmod +x "$vars_sh" 2>/dev/null || true
  . ./vars.sh 

########################################
# Check that required variables are set
########################################
: "${CPD_CLI_VERSION:?Please set CPD_CLI_VERSION variable in vars.sh file}"
export CPD_CLI_VERSION="${CPD_CLI_VERSION}"
: "${OS_ARCHITECTURE:?Please set OS_ARCHITECTURE variable in vars.sh file}"
export OS_ARCHITECTURE="${OS_ARCHITECTURE}"
 
 return 0
}
CPD_INSTALLER_OBJECTS


#################################################
# Progress Advisor
#################################################
progress_bar() {
    local duration=$1
    local bar_length=40
    local spin_chars=('🔄' '🔃' '🔁' '🔂')
    local spin_index=0

    echo -ne "["
    for ((i = 0; i < bar_length; i++)); do echo -ne "⚪"; done
    echo -ne "]\r["

    start_time=$(date +%s)
    while true; do
        elapsed=$(( $(date +%s) - start_time ))
        progress=$(( (elapsed * bar_length) / duration ))

        spin_char="${spin_chars[spin_index]}"
        spin_index=$(( (spin_index + 1) % 4 ))

        echo -ne "\r["
        for ((i = 0; i < progress; i++)); do echo -ne "🟢"; done
        for ((i = progress; i < bar_length; i++)); do echo -ne "🔵"; done
        echo -ne "] $spin_char"

        if [ $elapsed -ge $duration ]; then
            break
        fi
        sleep 0.1
    done

    echo -e "\n✅ Progress Completed! - 100%"
    YEAR=$(date +'%Y')
}


#################################################
# Extractor
#################################################
EXTRACTOR(){
  # after: tar -xzf "$FILENAME"
  # enter the extracted directory, tolerating build suffixes like -1841
  shopt -s nullglob

  dir=""
  # 1) prefer exact pattern with build suffix: cpd-cli-${OS_ARCHITECTURE}-${CPD_CLI_VERSION}-*/
  for d in "cpd-cli-${OS_ARCHITECTURE}-${CPD_CLI_VERSION}-"*/ ; do
    [[ -d "$d" ]] && dir="${d%/}" && break
  done

  # 2) fallback: version prefix only: cpd-cli-${OS_ARCHITECTURE}-${CPD_CLI_VERSION}*/
  if [[ -z "$dir" ]]; then
    for d in "cpd-cli-${OS_ARCHITECTURE}-${CPD_CLI_VERSION}"*/ ; do
      [[ -d "$d" ]] && dir="${d%/}" && break
    done
  fi

  shopt -u nullglob

  # 3) final safety: find the folder that contains the cpd-cli binary
  if [[ -z "$dir" ]]; then
    found_bin="$(find . -type f -name 'cpd-cli' -print -quit 2>/dev/null)"
    [[ -n "$found_bin" ]] && dir="$(dirname "$found_bin")"
  fi

  # 4) fail clearly if not found; otherwise cd
  if [[ -z "$dir" ]]; then
    echo "❌ Could not locate extracted cpd-cli directory."
    echo "   Looked for: cpd-cli-${OS_ARCHITECTURE}-${CPD_CLI_VERSION}-*/ and */cpd-cli"
    exit 1
  fi

  cd "$dir"
}


#################################################
# install cpd cli
#################################################
install_cpd_cli() {
  : "${CPD_CLI_VERSION:?CPD_CLI_VERSION not set}"
  : "${OS_ARCHITECTURE:?OS_ARCHITECTURE not set}"   # e.g., linux-EE, linux-SE, darwin-EE, ppc64le-SE, s390x-EE

  local base="https://github.com/IBM/cpd-cli/releases/download"
  local ver="v${CPD_CLI_VERSION}"
  local INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"

  # 1) Primary candidates: exactly as provided by OS_ARCHITECTURE
  #    Examples: cpd-cli-linux-EE-14.2.1.tgz, cpd-cli-linux-SE-14.2.1.tgz
  declare -a names
  names+=("cpd-cli-${OS_ARCHITECTURE}-${CPD_CLI_VERSION}")

  # 2) Fallback candidates (arch-style) — only if primary fails
  #    linux-amd64 or linux-arm64 (kept as safety for non-EE/SE assets)
  local arch="$(uname -m)"
  case "$arch" in
    x86_64|amd64) arch="amd64" ;;
    aarch64|arm64) arch="arm64" ;;
    ppc64le|s390x) arch="$arch" ;;       # in case IBM also ships arch-style for these
    *) arch="" ;;
  esac
  if [[ -n "$arch" ]]; then
    names+=("cpd-cli-linux-${arch}-${CPD_CLI_VERSION}")
  fi

  # Try each candidate with .tgz then .tar.gz
  local URL FILENAME EXTRACT_DIR
  for n in "${names[@]}"; do
    for ext in tgz tar.gz; do
      local try="${base}/${ver}/${n}.${ext}"
      echo "→ Probing ${try}"
      if curl -fsI -o /dev/null "$try"; then
        URL="$try"
        FILENAME="${n}.${ext}"
        EXTRACT_DIR="$n"
        break 2
      fi
    done
  done

  if [[ -z "$URL" ]]; then
    echo "❌ No matching asset found for CPD_CLI_VERSION=${CPD_CLI_VERSION}, OS_ARCHITECTURE=${OS_ARCHITECTURE}."
    echo "   Example (EE): https://github.com/IBM/cpd-cli/releases/download/v14.2.1/cpd-cli-linux-EE-14.2.1.tgz"
    return 1
  fi

  echo "📥 Downloading: $URL"
  curl -fSL --retry 3 --connect-timeout 10 -o "$FILENAME" "$URL" || { echo "❌ Download failed"; return 1; }

  # sanity check
  if ! gzip -t "$FILENAME" >/dev/null 2>&1; then
    echo "❌ Downloaded file is not a valid gzip (likely HTML/404)."
    return 1
  fi

  echo "📦 Extracting $FILENAME …"
  tar -xzf "$FILENAME" || { echo "❌ Extract failed"; return 1; }

  echo "🔧 Installing to $INSTALL_DIR …"
  sudo mkdir -p "$INSTALL_DIR"
  # cd "*$EXTRACT_DIR" 
  EXTRACTOR
  sudo mv cpd-cli "$INSTALL_DIR/cpd-cli"
  [[ -d plugins  ]] && sudo mv plugins  "$INSTALL_DIR/plugins"
  [[ -d LICENSES ]] && sudo mv LICENSES "$INSTALL_DIR/LICENSES"
  sudo chmod +x "$INSTALL_DIR/cpd-cli"

  echo "🧹 Cleaning up …"
  cd ..
  rm -f "$FILENAME"
  rm -rf "*$EXTRACT_DIR"

  echo "✅ Verifying …"
  "$INSTALL_DIR/cpd-cli" version || "$INSTALL_DIR/cpd-cli" --help
  echo "✅ cpd-cli ${CPD_CLI_VERSION} installed."
}

#=================
# Release Version
#=================
cpd_cli_check() {
  if command -v cpd-cli >/dev/null 2>&1; then
    progress_bar 5
    echo "✅ cpd-cli is already installed. Skipping installation."
    cpd-cli version
    exit 0
  else
    echo "✅ cpd-cli not installed, proceeding with installation..."
    progress_bar 5
    install_cpd_cli
  fi
}

#################################################
# Main:
#################################################
cpd_cli_check

