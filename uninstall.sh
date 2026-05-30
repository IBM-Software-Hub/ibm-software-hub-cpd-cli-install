#!/usr/bin/env bash
#shellcheck shell=bash

# @Author: Jeffrey Chijioke-Uche, Ph.D, IBM Computer Scientist & Quantum Ambassador / Data & AI Research Scientist
# @Description: Helper to uninstall IBM Software Hub CLI (cpd-cli).
# @Date: 2025-12-10
# @LICENSE: Apache License 2.0
# @Company: IBM


#-------------------------------------------------------------
# Internal worker: install a specific SWH CLI / cpd-cli version
# Usage: _swh_cli_install_engine <target_swh_version> <action>
#   target_swh_version: x.y.z (SWH release)
#   action: "install" | "upgrade" | "downgrade"
#-------------------------------------------------------------

source "$(dirname "$0")/swh_manager.sh"  # for header and summary logic

# if cpd-cli is not installed, switch to alternative presenter.
if ! command -v cpd-cli >/dev/null 2>&1; then
  header_1
else
  header_0
fi

# Ask User if they really want to uninstall and there must be yes|No
read -r -p "Are you sure you want to uninstall IBM Software Hub CLI (cpd-cli)? [y/N]: " confirm
confirm="${confirm,,}"  # to lowercase
if [[ "$confirm" != "y" && "$confirm" != "yes" ]]; then
  echo "✅ Operation cancelled by user."
  exit 0
else
  sudo rm -f /usr/local/bin/cpd-cli
  hash -r
  command -v cpd-cli || echo "cpd-cli successfully uninstalled."
  echo "Please wait..."
  echo "✅ IBM Software Hub CLI (cpd-cli) has been uninstalled."
fi


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
