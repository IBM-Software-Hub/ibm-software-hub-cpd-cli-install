#!/bin/bash

#---------------------------------------------------------------------------------------------------------------------
#                                 CLOUD PAK FOR DATA CLI INSTALLATION
#---------------------------------------------------------------------------------------------------------------------
# @Author:   Dr. Jeffrey Chijioke-Uche
# @Usage:    Install cpd-cli
# @License:  Opensource License

# License agreement prompt
license_accept() {
  BND="-----------------------------------------------------------------------------------------------------------------------------------------------"
  LIC="--------------------------------------------------------------------------------------------------------------------"
  LICENSE_FILE="$ROOT_DIR/LICENSE"
  echo ''
  echo "$BND"
  echo "📄 LICENSE AGREEMENT"
  echo "$BND"
  if [ -f "$LICENSE_FILE" ]; then
    cat "$LICENSE_FILE"
  else
    echo "❌ License file not found: $LICENSE_FILE"
    echo ''
    exit 1
  fi
  echo ''
  echo "$BND"
  echo -n "Do you accept the terms of the license? [accept/decline]: "
  read -r user_input

  case "$user_input" in
    accept|ACCEPT|Accept)
      echo "✅ License accepted. Proceeding with installation..."
      accepted_date=$(date +"%m-%d-%Y")
      accepted_file="$ROOT_DIR/license-accepted-$accepted_date"
      echo "STATUS: ACCEPTED" > "$accepted_file"
      echo "DATE ACCEPTED: $(date +"%m/%d/%Y")" >> "$accepted_file"
      echo "$LIC" >> "$accepted_file"
      cat "$LICENSE_FILE" >> "$accepted_file"
      ;;
    decline|DECLINE|Decline)
      echo "❌ License declined. Exited process. CLI software not Installed."
      exit 0
      ;;
    *)
      echo "⚠️ Invalid input. Please type 'accept' or 'decline'."
      exit 1
      ;;
  esac
}

# Run flow
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
license_accept
