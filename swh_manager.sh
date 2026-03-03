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


# List of IBM Product tag library:
ONBOARDING_FILE="0"
# Run once, parse twice
ver_out="$(cpd-cli version)"

cpd_cli_version="$(
  printf '%s\n' "$ver_out" | sed -n 's/^[[:space:]]*Version:[[:space:]]*\([0-9][0-9.]*\).*/\1/p'
)"
cpd_release_version="$(
  printf '%s\n' "$ver_out" | sed -n 's/^[[:space:]]*SWH[[:space:]]\+Release[[:space:]]\+Version:[[:space:]]*\([0-9][0-9.]*\).*/\1/p'
)"

export CLI_VERSION="CPD CLI VERSION $cpd_cli_version"
export SWH_RELEASE_VERSION="SWH Release Version $cpd_release_version"


export importlin='================================================================================================================================================'


export topliner='=================================================================================================================='


export senslin='===================================================================================================================='



export subliner='-------------------------------------------------------------------------------------------------------------------'



export unifier='------------------------------------------------'


export identifier1='            I  B  M    A  G E N T I C   A  I      '



export identifier2='                 I  B  M     A  D K        '



export identifier3='  I  B  M     A  G  E  N  T  I  C  ~ A  I   [ A  D  K]   '



export identifier4='

                                     IBM AGENTIC-AI END-TO-END WORKLOAD LIFECYCLE  [ ADK™  POWERED ]   '


export identifier5='

                                               HASHICORP - VAULT  [ Run as a Service™ ]   '


export identifier6='

                                               HASHICORP - TERRAFORM  [ Infrastructure as Code™ ]   '


export identifier7='

                                               IBM SOFTWARE HUB CLI  [ Workstation Tool Installation™ ]   '


export product="                            ${identifier4}                        
 ______     ______     ______     __  __     ______     ______     ______   ______     ______     ______   ______    
/\  __ \   /\  == \   /\  ___\   /\ \_\ \   /\  ___\   /\  ___\   /\__  _\ /\  == \   /\  __ \   /\__  _\ /\  ___\   
\ \ \/\ \  \ \  __<   \ \ \____  \ \  __ \  \ \  __\   \ \___  \  \/_/\ \/ \ \  __<   \ \  __ \  \/_/\ \/ \ \  __\   
 \ \_____\  \ \_\ \_\  \ \_____\  \ \_\ \_\  \ \_____\  \/\_____\    \ \_\  \ \_\ \_\  \ \_\ \_\    \ \_\  \ \_____\ 
  \/_____/   \/_/ /_/   \/_____/   \/_/\/_/   \/_____/   \/_____/     \/_/   \/_/ /_/   \/_/\/_/     \/_/   \/_____/
                                             
                                        
"



export vault_product="                            ${identifier5}                        
 __  __     ______     ______     __  __     __     ______     ______     ______     ______      __   __   ______     __  __     __         ______  
/\ \_\ \   /\  __ \   /\  ___\   /\ \_\ \   /\ \   /\  ___\   /\  __ \   /\  == \   /\  == \    /\ \ / /  /\  __ \   /\ \/\ \   /\ \       /\__  _\ 
\ \  __ \  \ \  __ \  \ \___  \  \ \  __ \  \ \ \  \ \ \____  \ \ \/\ \  \ \  __<   \ \  _-/    \ \ \'/   \ \  __ \  \ \ \_\ \  \ \ \____  \/_/\ \/ 
 \ \_\ \_\  \ \_\ \_\  \/\_____\  \ \_\ \_\  \ \_\  \ \_____\  \ \_____\  \ \_\ \_\  \ \_\       \ \__|    \ \_\ \_\  \ \_____\  \ \_____\    \ \_\ 
  \/_/\/_/   \/_/\/_/   \/_____/   \/_/\/_/   \/_/   \/_____/   \/_____/   \/_/ /_/   \/_/        \/_/      \/_/\/_/   \/_____/   \/_____/     \/_/ 

                                                   
"



export terraform_product="                            ${identifier6}   
                         ______   ______     ______     ______     ______     ______   ______     ______     __    __    
                        /\__  _\ /\  ___\   /\  == \   /\  == \   /\  __ \   /\  ___\ /\  __ \   /\  == \   /\ \-./  \   
                        \/_/\ \/ \ \  __\   \ \  __<   \ \  __<   \ \  __ \  \ \  __\ \ \ \/\ \  \ \  __<   \ \ \-./\ \  
                           \ \_\  \ \_____\  \ \_\ \_\  \ \_\ \_\  \ \_\ \_\  \ \_\    \ \_____\  \ \_\ \_\  \ \_\ \ \_\ 
                            \/_/   \/_____/   \/_/ /_/   \/_/ /_/   \/_/\/_/   \/_/     \/_____/   \/_/ /_/   \/_/  \/_/ 
                                                                                                                                                                                                                                                                                                                                                                                             
                                                                                                                                         
"


export header="                            ${identifier7}   
                                     __     ______     __    __        __  __     __  __     ______    
                                    /\ \   /\  == \   /\ \-./  \      /\ \_\ \   /\ \/\ \   /\  == \   
                                    \ \ \  \ \  __<   \ \ \-./\ \     \ \  __ \  \ \ \_\ \  \ \  __<   
                                     \ \_\  \ \_____\  \ \_\ \ \_\     \ \_\ \_\  \ \_____\  \ \_____\ 
                                      \/_/   \/_____/   \/_/  \/_/      \/_/\/_/   \/_____/   \/_____/ 

                                                    ${SWH_RELEASE_VERSION}
"


header(){
    echo "$LINER"
    echo "IBM Software Hub Command Line Interface (CLI) Management Solution Center - $THIS_DAY" 
    echo "$LINER"
    echo "${header}"
    echo "$LINER"
}
