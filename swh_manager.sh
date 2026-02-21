#!/usr/bin/env bash

set -Eeuo pipefail

# @Author: Jeffrey Chijioke-Uche, Ph.D, IBM Computer Scientist & Quantum Ambassador / Data & AI Research Scientist
# @Description: Helper to install, upgrade, or downgrade IBM Software Hub CLI (cpd-cli) to a specified version.
# @Date: 2025-12-10
# @LICENSE: Apache License 2.0
# @Company: IBM

echo
#-------------------------------------------------------------------------------
START_TIME=$(date +%s)
CHOICE_CODE=200
THIS_DAY=$(date +"%B %d, %Y, %-I:%M %P %Z")
#------------------------------------------------------------------------------
OPERATION="IBM SWH CLI (cpd-cli) Management"

LINER="_______________________________________________________________________________________________________________________"
export LINER="$LINER"

header(){
    echo "$LINER"
    echo "IBM Software Hub Command Line Interface (CLI) Management Solution Center - $THIS_DAY" 
    echo "$LINER"
    echo "
    ooooo oooooooooo oooo     oooo       oooooooo8 oooo     oooo ooooo ooooo      ooooo ooooo ooooo  oooo oooooooooo  
    888   888    888 8888o   888       888         88   88  88   888   888        888   888   888    88   888    888 
    888   888oooo88  88 888o8 88        888oooooo   88 888 88    888ooo888        888ooo888   888    88   888oooo88  
    888   888    888 88  888  88               888   888 888     888   888        888   888   888    88   888    888 
    o888o o888ooo888 o88o  8  o88o      o88oooo888     8   8     o888o o888o      o888o o888o   888oo88   o888ooo888  
    "
    echo "$LINER"
}