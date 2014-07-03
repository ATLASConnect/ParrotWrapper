#!/bin/sh

# Local additions when setting up DQ2

# DQ2 uses $USER to create a unique /var/tmp/.dq2$USER/TiersOfAtlas.py
[[ -z $USER ]] && export USER=$(whoami)

# Default to the MWT2 Scratch disk
export DQ2_LOCAL_SITE_ID=MWT2_UC_SCRATCHDISK

# The OSG server
export LCG_GFAL_INFOSYS=is.grid.iu.edu:2170
