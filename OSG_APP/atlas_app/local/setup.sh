# Local setup

# Where are we running
localHome="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


# Where to find the Atlas Conditions
export ATLAS_POOLCOND_PATH="/cvmfs/atlas-condb.cern.ch/repo/conditions"


# Turn on Frontier warnings
export FRONTIER_LOG_LEVEL=warning
#export FRONTIER_READTIMEOUTSECS=60


# Tell the Pilot that we are not a local scratch disk
export NON_LOCAL_ATLAS_SCRATCH=true

# Scan for space utilization every 90 minutes (10 minute increments)
export NON_LOCAL_ATLAS_SCRATCH_SPACE=9



# dCache setup
#export DCACHE_RAHEAD=TRUE
#export DCACHE_RA_BUFFER=32768
#export DC_LOCAL_CACHE_BUFFER=1
#export DC_LOCAL_CACHE_BLOCK_SIZE=131072
#export DC_LOCAL_CACHE_MEMORY_PER_FILE=10000000
#export DCACHE_CLIENT_ACTIVE=true

# SRM options
#SRM_JAVA_OPTIONS="-Xms64m -Xmx64m -client"


# Fix a VOMS proxy error
#export VOMS_PROXY_INFO_DONT_VERIFY_AC="true"
