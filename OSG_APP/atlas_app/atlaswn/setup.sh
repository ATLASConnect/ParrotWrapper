#!/bin/sh


# Setup DQ2 and Rucio Client
source /cvmfs/atlas.cern.ch/repo/sw/ddm/latest/setup.sh


# The setup for DQ2 will always set RUCIO_ACCOUNT=pilot
# We want to change it to our proxy nickname if available

# Extract the Account name from the nickname field of the proxy
myAccount=$(sh -c 'voms-proxy-info --all 2>/dev/null'|grep 'attribute : nickname ='|awk '{print $5}')

# If we got an account, setup Rucio to use it
[[ -n "${myAccount}" ]] && export RUCIO_ACCOUNT=${myAccount}
