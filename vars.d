#!/usr/bin/env bash

#@Last modified: 2025-08-20
#@Version: 1.3.04
#@License: Apache License 2.0
#---------------------------------------------------------------------------------------------------------------------
#                                 CLOUD PAK FOR DATA CLI INSTALLATION
#---------------------------------------------------------------------------------------------------------------------
# @Author: Dr. Jeffrey Chijioke-Uche
# @Maintainer: Dr. Jeffrey Chijioke-Uche
# @Usage: Install cpd-cli variable definition

# Reference:  https://github.com/IBM/cpd-cli/releases
# -----------------------------------------------------------------------------
# CLI         | OS_ARCHITECTURE  | CPD_CLI_VERSION | CPD_VERSION
# -----------------------------------------------------------------------------
# cpd-cli     | darwin-EE        | 14.2.1          | 5.2.1
# cpd-cli     | darwin-SE        | 14.2.1          | 5.2.1
# cpd-cli     | linux-EE         | 14.2.1          | 5.2.1
# cpd-cli     | linux-SE         | 14.2.1          | 5.2.1
# cpd-cli     | ppc64le-EE       | 14.2.1          | 5.2.1
# cpd-cli     | ppc64le-SE       | 14.2.1          | 5.2.1
# cpd-cli     | s390x-EE         | 14.2.1          | 5.2.1
# cpd-cli     | s390x-SE         | 14.2.1          | 5.2.1
# -----------------------------------------------------------------------------

####################
# Default settings
####################
CPD_CLI_VERSION="<!---provide-version--->"
export CPD_CLI_VERSION="${CPD_CLI_VERSION}"