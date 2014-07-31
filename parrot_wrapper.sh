#!/bin/bash

######################################################################################


# The version of the wrapper
export parrotWrapperVersion="2.0-10"


######################################################################################
# Native CVMFS, nfsCVMFS, PortableCVMFS, Parrot/CVMFS or Parrot/Chirp Wrapper
######################################################################################
# 
#
# The following variables will modify the action taken by the Parrot Wrapper
# 
# These should be set in the setup_site.sh script based on the requirements of the site
#
# At the minimum, $cvmfsType should be defined to one of the following values
#
# 	native		Use System installed CVMFS,    HEPOS_libs and Certificate Authority
#	parrot		Use Parrot to access CVMFS,    ACE Cache available
#	nfs		Use System installed nfsCVMFS, ACE Cache available
#	portable	Use PortableCVMFS,             ACE Cache available
#
# Default value for $cvmfsType is "native"
#
#
# The ACE Cache contains and ACE Image (for HEPOS_lib), OSG WN Client and a Certicate Authority
# The ACE Cache componitents can be local (default tarball installation) or a CVMFS repository
# The ACE Image can be bypassed and the System libraries used
#
# If Parrot/CVMFS is used, Parrot can "mount" access into the ACE Image
#
#
######################################################################################
#
# If parrotUseNativeONLY is defined, use Native access for all components
#
# These include
#
#	CVMFS Client	"Native" installation of "/cvmfs" and all CERN repositories (MWT2 might not be available)
#	HEP_OSlibs	Installed on the system along with all other needed compatibility libraries
#	$OSG_APP	Defined by the system or within setup_site.sh
#	$OSG_GRID	Defined by the system or within setup_site.sh
#	$OSG_WN_TMP	Setup by this wrapper within the job sandbox
#	$X509_CERT_DIR	Defined by the system or within setup_site.sh or a CA at /etc/grid-security/certificates
#
#export parrotUseNativeONLY=True


# If parrotUsePortableCVMFS is defined, use PortableCVMFS to access all /cvmfs repositories
# By default, it is assume that /cvmfs is mounted locally
# The wrapper will setup access to an ACE Image (via env var), OSG WN Client and Certficate Authority
#export parrotUsePortableCVMFS=True


# If parrotUseParrotCVMFS is defined, use Parrot to access all /cvmfs repositories
# By default, it is assume that /cvmfs is mounted locally
# The wrapper will setup access to an ACE Image (via parrot mounts), OSG WN Client and Certficate Authority
#export parrotUseParrotCVMFS=True


# If parrotUseParrotChirp is defined, we will use a Chirp Server to access /cvmfs
# By default, Parrot/CVMFS will be used to access all CVMFS repositories
# This setting only has meaning if parrotUseParrotCVMFS is also defined
#export parrotUseParrotChirp=True


# If parrotUseParrotMount is defined (and useing Parrot for CVMFS access), use Parrot --mount to access ACE Image
# By default, ACE Image access will be via environment variables (same as other CVMFS access types)
#export parrotUseParrotMount=True


# If parrotUseCVMFSaceImageTB is defined, we will use an ACE Image from a Tarball installed in the ACE Cache
# By default, an ACE Image from a CVMFS repository will be used
#export parrotUseCVMFSaceImageTB=True


# If parrotUseCVMFSaceWNCtb is defined, we will use the OSG WN Client from a Tarball installed in the ACE Cache
# By default, the OSG WNC Client from a CVMFS repository will be used
#export parrotUseCVMFSaceWNCtb=True


# If parrotUseCVMFSaceCAtb is defined, we will use a Certificate Authority from an installation in the ACE Cache
# By default, a Certificate Authority from a CVMFS repoisitory will be used
#export parrotUseCVMFSaceCAtb=True


# If parrotUseSystemLIB is defined, we will use an local System libraries for HEPOS_libs, etc
# By default, LD_LIBRARY_PATH, etc will be modified to use the ACE Image libraries
#export parrotUseSystemLIB=True


# If parrotUseThreadCloneFix is defined, we will use the Parrot Thread Clone Bugfix
# By default, the Bugfix will not be used
# Use of this feature will most likley have sever impact on performance
# Only 4.1.4rc5 currently supports this feature
#export parrotUseThreadCloneFix=True


# If parrotUseCachePerJob is defined, we setup a Per Job Private Cache
# By default, the Parrot Cache is shared by all jobs on the same node
#export parrotUseCachePerJob=True


# The Chirp Server upon which the CVMFS repositories are statically mounted and accessible
#export parrotChirpServer="uct2-c320.mwt2.org"
#export parrotChirpServer="uct2-int.mwt2.org"


# The blocksize to use for Parrot/Chirp, 1M or 2M
#export parrotChirpBlocksize=1048576
#export parrotChirpBlocksize=2097152


# Location of the ACE Image if parrotUseCVMFSaceImageTB is not defined
#export parrotCVMFSaceImage=/cvmfs/osg.mwt2.org/atlas/sw/ACE/current
#export parrotCVMFSaceImage=/cvmfs/cernvm-prod.cern.ch/cvm3


# Location of the OSG WN Client if parrotUseCVMFSaceWNCtb is not defined
#export parrotCVMFSaceWNC=/cvmfs/osg.mwt2.org/osg/sw


# Location of the Certificate Authority repository if parrotUseCVMFSaceCAtb is not defined
#export parrotCVMFSaceCA=/cvmfs/osg.mwt2.org/osg/CA


######################################################################################
# Basic Parrot defintions we need to start
######################################################################################

# Signal list for traps
export parrotTRAP="EXIT HUP INT TERM QUIT ABRT ILL BUS FPE"

# Save the command line to be executed
export parrotCMD="$@"

# Where we have various appliations need for a Parrot based CVMFS
export parrotHome="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


######################################################################################
# Function definitions
######################################################################################

source ${parrotHome}/functions.sh


#########################################################################################
# Site definitions
#########################################################################################

# Setup the local site definitions
source ${parrotHome}/setup_site.sh


#########################################################################################
# Based on CVMFS Access Type, etc, make certain definitions make sense
#########################################################################################

# If we have not defined a CVMFS access type, use undefined
[[ -z "${cvmfsType}" ]] && export cvmfsType="undefined"


# Set value values based on the CVMFS Access Type

case ${cvmfsType} in

  # Use Parrot to access /cvmfs

  (parrot)

    export parrotUseNativeONLY=''
    export parrotUseParrotCVMFS=True
    export parrotUseNfsCVMFS=''
    export parrotUsePortableCVMFS=''

  ;;


  # Use nfsCVMFS to access /cvmfs

  (nfs)

    export parrotUseNativeONLY=''
    export parrotUseParrotCVMFS=''
    export parrotUseNfsCVMFS=True
    export parrotUsePortableCVMFS=''

  ;;


  # Use PorableCVMFS to access /cvmfs

  (portable)

    export parrotUseNativeONLY=''
    export parrotUseParrotCVMFS=''
    export parrotUseNfsCVMFS=''
    export parrotUsePortableCVMFS=True

  ;;


  # By default, CVMFS access will be Native

  (*)

    export parrotUseNativeONLY=True
    export parrotUseParrotCVMFS=''
    export parrotUsePortableCVMFS=''
    export parrotUseNfsCVMFS=''
    export parrotUseSystemLIB=True

  ;;


esac


# If we are using tye System libraries (not the ACE Image), undefine UseParrotMount
[[ -n "${parrotUseSystemLIB}" ]] && export parrotUseParrotMount=''


# The Chirp Server upon which the CVMFS repositories are statically mounted and accessible
[[ -z "${parrotChirpServer}" ]] && export parrotChirpServer="uct2-int.mwt2.org"
#[[ -z "${parrotChirpServer}" ]] && export parrotChirpServer="uct2-c320.mwt2.org"

# The blocksize to use for Parrot/Chirp, 1M or 2M
[[ -z "${parrotChirpBlocksize}" ]] && export parrotChirpBlocksize=2097152
#[[ -z "${parrotChirpBlocksize}" ]] && export parrotChirpBlocksize=1048576



# Location of the ACE Image if parrotUseCVMFSaceImageTB is not defined
[[ -z "${parrotCVMFSaceImage}" ]] && export parrotCVMFSaceImage=/cvmfs/osg.mwt2.org/atlas/sw/ACE/current
#[[ -z "${parrotCVMFSaceImage}" ]] && export parrotCVMFSaceImage=/cvmfs/cernvm-prod.cern.ch/cvm3

# Location of the OSG WN Client if parrotUseCVMFSaceWNCtb is not defined
[[ -z "${parrotCVMFSaceWNC}" ]] && export parrotCVMFSaceWNC=/cvmfs/osg.mwt2.org/osg/sw

# Location of the Certificate Authority if parrotUseCVMFSaceCAtb is not defined
[[ -z "${parrotCVMFSaceCA}" ]] && export parrotCVMFSaceCA=/cvmfs/osg.mwt2.org/osg/CA


#########################################################################################
# Additional CVMFS repositories not provided by default in Parrot 
#########################################################################################

# Repository keys
export cvmfsKeyCERN="${parrotHome}/cern.ch.pub"
export cvmfsKeyMWT2="${parrotHome}/osg.mwt2.org.pub"

# CERN Production repository "cernvm-prod.cern.ch"
export cvmfsRepoCERNVM="cernvm-prod.cern.ch:url=http://cvmfs-stratum-one.cern.ch/opt/cernvm-prod;http://cernvmfs.gridpp.rl.ac.uk/opt/cernvm-prod;http://cvmfs.racf.bnl.gov/opt/cernvm-prod,pubkey=${cvmfsKeyCERN},proxies=${cvmfsProxy}"

# CERN Geant4
export cvmfsRepoGEANT4="geant4.cern.ch:url=http://cvmfs-stratum-one.cern.ch/opt/geant4;http://cernvmfs.gridpp.rl.ac.uk/opt/geant4;http://cvmfs.racf.bnl.gov/opt/geant4,pubkey=${cvmfsKeyCERN},proxies=${cvmfsProxy}"

# MidWest Tier2 repository "osg.mwt2.org"
export cvmfsRepoMWT2="osg.mwt2.org:url=http://uct2-cvmfs.mwt2.org/opt/osg;http://iut2-cvmfs.mwt2.org/opt/osg;http://mwt2-cvmfs.campuscluster.illinois.edu/opt/osg,pubkey=${cvmfsKeyMWT2},proxies=${cvmfsProxy}"


# The repositories we will use
export cvmfsRepoList="${cvmfsRepoMWT2} ${cvmfsRepoCERNVM} ${cvmfsRepoGEANT4}"


#########################################################################################
# Parrot Run definitions
#########################################################################################

# Parrot Helper location
export PARROT_HELPER="${parrotHome}/\$LIB/libparrot_helper.so"

# Some executables we need
export parrotBIN="${parrotHome}/bin"


# Libraries needed to make Parrot work
export parrotLIB="${parrotHome}/lib64:${parrotHome}/lib"

# Add the local libraries needed to make parrot work on a the target node
if [[ -z "${LD_LIBRARY_PATH}" ]]; then
  export LD_LIBRARY_PATH=${parrotLIB}
else
  export LD_LIBRARY_PATH=${parrotLIB}:${LD_LIBRARY_PATH}
fi


# Local Python modules needed by Altas releases, etc
export parrotPYTHONPATH="${parrotHome}/python"

# Add the local python modules needed to make parrot work on a the target node
if [[ -z "${PYTHONPATH}" ]]; then
  export PYTHONPATH=${parrotPYTHONPATH}
else
  export PYTHONPATH=${parrotPYTHONPATH}:${PYTHONPATH}
fi


# Get the version of Parrot we are running
export parrotVersion=$(echo $(${parrotBIN}/parrot_run --version) | cut -f3 -d' ')

# Hopefully CCTools will define $PARROT_VERSION in a future release
[[ -z "${PARROT_VERSION}" ]] && export PARROT_VERSION=${parrotVersion}


######################################################################################
# Additions for parrot_run
######################################################################################

# If we are using a Chirp Server to access the CVMFS repositories,
# enabled the "auth" and map all references to /cvmfs into /chirp on the Chirp Server

if [[ -n "${parrotUseParrotChirp}" ]]; then
  export parrotRunChirp="--block-size ${parrotChirpBlocksize} --chirp-auth hostname --mount /cvmfs=/chirp/${parrotChirpServer}"
fi



# Should we enable the Thread Clone Bugfix (only support in select version of Parrot)
# This will most likely have severe impact on the performance of the job

if [[ -n "${parrotUseThreadCloneFix}" ]]; then
  if [[ "${parrotVersion}" == "4.1.4rc5-TRUNK" ]]; then
    export parrotRunCVMFS="--cvmfs-enable-thread-clone-bugfix"
  fi
fi


#########################################################################################
# Parrot Cache definitions
#########################################################################################

# Location of Parrot Root with a default to /tmp
[[ -z ${parrotRoot} ]] && export parrotRoot=/tmp

# Full path to the Parrot cache for all users on this node
export parrotCacheRoot=${parrotRoot}/parrotCache

# Each user has a private cache which will be rolled daily
export parrotCacheUserRoot=${parrotCacheRoot}.$(whoami)

# Create the User Root 
mkdir -p ${parrotCacheUserRoot}; chmod 700 ${parrotCacheUserRoot}

# Due to Cache Bloat, we will roll the cache daily per user
export parrotCacheDailyRoot=${parrotCacheUserRoot}/$(date +%Y%m%d)

# Create the Daily Cache location
mkdir -p ${parrotCacheDailyRoot}; chmod 700 ${parrotCacheDailyRoot}

# Location of the Parrot and CVMFS alien caches
export parrotCache=${parrotCacheDailyRoot}/cache

# Create the Cache location
mkdir -p ${parrotCache}; chmod 700 ${parrotCache}


#########################################################################################
# ACE Cache definitions
#########################################################################################

# Location of the ACE Root with a default to where the Parrot Cache is located
[[ -z ${aceRoot} ]] && export aceRoot=${parrotRoot}

# Full path to the ACE cache for all users on this node
export aceCacheRoot=${aceRoot}/aceCache

# Each user has a private cache which will be rolled daily
export aceCacheUserRoot=${aceCacheRoot}.$(whoami)

# Create the User Root 
mkdir -p ${aceCacheUserRoot}; chmod 700 ${aceCacheUserRoot}

# To pick up any changes, roll the cache daily
export aceCacheDailyRoot=${aceCacheUserRoot}/$(date +%Y%m%d)

# Create the Daily Cache location
mkdir -p ${aceCacheDailyRoot}; chmod 700 ${aceCacheDailyRoot}

# Make the Daily Cache the active location
export aceCache=${aceCacheDailyRoot}



# Location of the CA

if [[ -n "${parrotUseCVMFSaceCAtb}" ]]; then
  export aceCA=${aceCache}/CA
else
  export aceCA=${parrotCVMFSaceCA}
fi


# Location of the ACE OSG WN Client

if [[ -n "${parrotUseCVMFSaceWNCtb}" ]]; then
  export aceWNC=${aceCache}/osg
else
  export aceWNC=${parrotCVMFSaceWNC}
fi


# Location of the ACE Image (CVMFS or the ACE Cache)

if [[ -n "${parrotUseCVMFSaceImageTB}" ]]; then
  export aceImage=${aceCache}/ACE
else
  export aceImage=${parrotCVMFSaceImage}
fi


# Location of the ACE etc
export aceEtc=${aceCache}/etc

# Location of the ACE etc
export aceVar=${aceCache}/var


#########################################################################################
# Start of execution
#########################################################################################

echo "################################################################################"

# Display the Parrot Wrapper to help us debug
f_echo "Parrot Wrapper Version ${parrotWrapperVersion}"

f_echo "CVMFS Access Type         = ${cvmfsType}"

if [[ -n "${parrotUseNativeONLY}" ]]; then
  f_echo "CVMFS Repository Access   = Native CVMFS"
elif [[ -n "${parrotUseNfsCVMFS}" ]]; then
  f_echo "CVMFS Repository Access   = nfsCVMFS"
elif [[ -n "${parrotUsePortableCVMFS}" ]]; then
  f_echo "CVMFS Repository Access   = PortableCVMFS"
elif [[ -n "${parrotUseParrotCVMFS}" ]]; then

  if [[ -n "${parrotUseParrotChirp}" ]]; then
    f_echo "CVMFS Repository Access   = Parrot/Chirp Version ${parrotVersion}"
    f_echo "Chirp Server              = ${parrotChirpServer}"
    f_echo "Chirp Server Blocksize    = ${parrotChirpBlocksize}"
    f_echo "ParrotRunChirp            = ${parrotRunChirp}"
  else
    f_echo "CVMFS Repository Access   = Parrot/CVMFS Version ${parrotVersion}"
  fi

  if [[ -n "${parrotUseParrotMount}" ]]; then
    f_echo "Parrot Mount              = Enabled"
  else
    f_echo "Parrot Mount              = Disabled"
  fi

  f_echo "ParrotRunCVMFS            = ${parrotRunCVMFS}"

else
  f_echo "CVMFS Repository Access   = *Unknown*"
fi


f_echo "Kernel                    = $(uname --kernel-release)"

if [[ -n "${parrotUseNativeONLY}" ]]; then
  f_echo "ACE Cache                 = Disabled"
else
  f_echo "ACE Cache                 = Enabled"
  f_echo "ACE Certificate Authority = ${aceCA}/certificates"
  f_echo "ACE Worker Node Client    = ${aceWNC}/osg-wn-client"
  f_echo "ACE Image                 = ${aceImage}"

  # ACE etc and var are only needed if we are using Parrot for CVMFS access
  if [[ -n "${parrotUseParrotCVMFS}" ]]; then
    f_echo "ACE etc                   = ${aceEtc}"
    f_echo "ACE var                   = ${aceVar}"
  fi

  if [[ -n "${parrotUseSystemLIB}" ]]; then
    f_echo "ACE Image Libraries       = Disabled"
  else
    f_echo "ACE Image Libraries       = Enabled"
  fi
fi


#########################################################################################
# Make a unique Parrot cache for every job
#########################################################################################

# Make a unique location for job due to parrot bugs
# We remove this tmp cache at job end (see below)

if [[ -n "${parrotUseCachePerJob}" ]]; then
  export parrotCache=$(mktemp -d -p ${parrotCache} tmp.XXX)
  f_echo "Private Parrot Cache      = ${parrotCache}"
fi


#########################################################################################
# Add anything missing to $PATH
#########################################################################################

f_addpath "/usr/bin"
f_addpath "/bin"
f_addpath "/usr/sbin"
f_addpath "/sbin"


#########################################################################################
# Setup the ulimits for this job
#########################################################################################

# Fill in some defaults we would like to use

[[ -z "${ulimitOpenFiles}"   ]] && ulimitOpenFiles=65536
[[ -z "${ulimitStackSize}"   ]] && ulimitStackSize=unlimited
[[ -z "${ulimitMaxUserProc}" ]] && ulimitMaxUserProc=unlimited


# Set the various ulimits for the job using any values set in setup_site.sh

f_ulimit -t  hard ${ulimitCPU}
f_ulimit -d  hard ${ulimitDataSeg}
f_ulimit -f  hard ${ulimitFileSize}
f_ulimit -l  hard ${ulimitMaxLockMem}
f_ulimit -n  hard ${ulimitOpenFiles}
f_ulimit -s  hard ${ulimitStackSize}
f_ulimit -m  hard ${ulimitMaxMem}
f_ulimit -u  hard ${ulimitMaxUserProc}
f_ulimit -v  hard ${ulimitVirMem}
f_ulimit -x  hard ${ulimitFileLocks}

#f_ulimit -n 4096      ${ulimitOpenFiles}
#f_ulimit -c ''        ${ulimitCoreFileSize}
#f_ulimit -e ''        ${ulimitSchedPrio}
#f_ulimit -i ''        ${ulimitPendSig}
#f_ulimit -p ''        ${ulimitPipeSize}
#f_ulimit -q ''        ${ulimitPOSIXMesQ}
#f_ulimit -r ''        ${ulimitRTPrio}

f_echo
f_echo "Executing command: ulimit -S -a"
f_echo

ulimit -S -a

f_echo


#########################################################################################
# Cleanup old Parrot and ACE Cache directories
#########################################################################################

# First clean out old Daily Caches in case we need the space

f_echo "Requesting a lock for the Parrot Cache"

# Lock the Parrot Cache User Root to only allow one job to cleanup with a 1 hour timeout on the lock
${parrotBIN}/lockfile -0 -r 0 -s 0 -l $((60*60)) ${parrotCacheUserRoot}.lock 2> /dev/null

# Proceed only if we got the lock
if [[ $? -ne 0 ]]; then
  f_echo "Parrot Cache locked - Skipping purge of old Parrot Caches"
else

  f_echo "Purge Parrot Cache from ${parrotCacheUserRoot}"

  # If we exit too soon try to cleanup the lock
  trap "rm -f ${parrotCacheUserRoot}.lock; exit" ${parrotTRAP}

  # Cleanup the Parrot User Cache area of any directories older than 7 days
  find  ${parrotCacheUserRoot}/* -ignore_readdir_race -maxdepth 0 -xdev -atime +7 -type d -exec rm -rf {} \;

  f_echo "Purge Parrot Cache complete"

  f_echo "Releasing the lock on the Parrot Cache"
  rm -f ${parrotCacheUserRoot}.lock

  # Clear the traps since we are now done
  trap - ${parrotTRAP}

fi


f_echo "Requesting a lock for the ACE Cache"

# Lock the ACE Cache User Root to only allow one job to cleanup with a 1 hour timeout on the lock
${parrotBIN}/lockfile -0 -r 0 -s 0 -l $((60*60)) ${aceCacheUserRoot}.lock 2> /dev/null

# Proceed only if we got the lock
if [[ $? -ne 0 ]]; then
  f_echo "ACE Cache locked - Skipping purge of old ACE Caches"
else

  f_echo "Purge ACE Cache from ${aceCacheUserRoot}"

  # If we exit too soon try to cleanup the lock
  trap "rm -f ${aceCacheUserRoot}.lock; exit" ${parrotTRAP}

  # Cleanup the ACE User Cache area of any directories older than 7 days
  find  ${aceCacheUserRoot}/* -ignore_readdir_race -maxdepth 0 -xdev -atime +7 -type d -exec rm -rf {} \;

  f_echo "Purge ACE Cache complete"

  f_echo "Releasing the lock on the ACE Cache"
  rm -f ${aceCacheUserRoot}.lock

  # Clear the traps since we are now done
  trap - ${parrotTRAP}

fi


#########################################################################################
# Setup the ACE Image
#########################################################################################

# Setup the Atlas Compliant Environment (ACE) Image unless we are to use the System libraries

if [[ -z "${parrotUseSystemLIB}" ]]; then

  source ${parrotHome}/setup_ace.sh

  # Save the ACE installation status
  aceStatus=$?

  if [[ ${aceStatus} -ne 0 ]]; then
     f_echo
     f_echo "Aborting job: Unable to setup the ACE Image with error ${aceStatus}"
     f_echo
     exit ${aceStatus}
  fi

fi


#########################################################################################
# Setup the ACE OSG WN Client
#########################################################################################

# Setup OSG WN Client, useless we are using NativeONLY

if [[ -z "${parrotUseNativeONLY}" ]]; then

  source ${parrotHome}/setup_osg.sh

  # Save the ACE installation status
  osgStatus=$?

  if [[ ${osgStatus} -ne 0 ]]; then
     f_echo
     f_echo "Aborting job: Unable to setup the ACE OSG WN Client with error ${osgStatus}"
     f_echo
     exit ${osgStatus}
  fi

fi


#########################################################################################
# Setup the Certificate Authority
#########################################################################################

# Setup or update the ACE Certifiate Authority unless we are Native Only

if [[ -z "${parrotUseNativeONLY}" ]]; then

  source ${parrotHome}/setup_ca.sh

  # Save the ACE CA installation status
  caStatus=$?

  if [[ ${caStatus} -ne 0 ]]; then
     f_echo
     f_echo "Aborting job: Unable to setup the ACE Certificate Authority with error ${aceStatus}"
     f_echo
     exit ${caStatus}
  fi

fi


#########################################################################################
# Define OSG variables normally setup on a CE
#########################################################################################

# OSG_APP, OSG_GRID and OSG_WN_TMP are defined here. All other Pilot variables are defined in the APF


# Use a local $OSG_APP as defined by the system or setup_site.sh
# Otherwise use the $OSG_APP included with the ParrotWrapper

if [[ -n "${parrotUseNativeONLY}" ]]; then

  # If the system has not defined a $OSG_APP, use the one in the ParrotWrapper

  if [[ -z "${OSG_APP}" ]]; then
    export OSG_APP=${parrotHome}/OSG_APP
    export ATLAS_LOCAL_AREA=${OSG_APP}/atlas_app/local
  fi

else

  # For most CVMFS Access Types, always use a $OSG_APP packaged with ParrotWrapper

  export OSG_APP=${parrotHome}/OSG_APP
  export ATLAS_LOCAL_AREA=${OSG_APP}/atlas_app/local

fi

f_echo "\$OSG_APP                  = ${OSG_APP}"
f_echo "\$ATLAS_LOCAL_AREA         = ${ATLAS_LOCAL_AREA}"


# Use a local $OSG_GRID (OSG WN Client) as defined by the system or setup_site.sh
# Otherwise use a $OSG_GRID (OSG WN Client) from the ACE Cache as installed by setup_ace.sh

if [[ -z "${parrotUseNativeONLY}" ]]; then
  export OSG_GRID=${aceWNC}/osg-wn-client
fi

if [[ -n "${OSG_GRID}" ]]; then
  f_echo "\$OSG_GRID                 = ${OSG_GRID}"
else
  f_echo "\$OSG_GRID                 = *SYSTEM*"
fi


# Use the specified worker node temp area

if [[ -n ${_condor_LOCAL_DIR} ]]; then
  export OSG_WN_TMP=${_condor_LOCAL_DIR}/scratch
else
  export OSG_WN_TMP=${aceCache}/scratch
fi

# Make certain the OSG WN scratch exists
mkdir -p ${OSG_WN_TMP}

f_echo "\$OSG_WN_TMP               = ${OSG_WN_TMP}"


# Define a proxy to use

if [[ -n "${parrotUseNativeONLY}" ]]; then
  f_echo "\$HTTP_PROXY               = *SYSTEM*"
else
  export HTTP_PROXY=${parrotProxy}
  f_echo "\$HTTP_PROXY               = ${HTTP_PROXY}"
fi



# Default Certificate Authority (osg-wn-client may override this value)

if [[ -n "${parrotUseNativeONLY}" ]]; then
  f_echo "\$X509_CERT_DIR            = *SYSTEM*"
else
  export X509_CERT_DIR=${aceCA}/certificates
  f_echo "\$X509_CERT_DIR            = ${X509_CERT_DIR}"
fi


# DQ2 uses $USER to create a unique /var/tmp/.dq2$USER/TiersOfAtlas.py
[[ -z $USER ]] && export USER=$(whoami)


#########################################################################################
# Make a unique Parrot cache for every job
#########################################################################################

# Make a unique location for job due to parrot bugs
# We remove this tmp cache at job end (see below)

if [[ -n "${parrotUseCachePerJob}" ]]; then
  export parrotCache=$(mktemp -d -p ${parrotCache} tmp.XXX)
  f_echo "Private Parrot Cache      = ${parrotCache}"
fi


#########################################################################################
# Redirect the various Temporary paths to avoid long paths
#########################################################################################

# Create some softlinks to $TMP, $TEMP and $TMPDIR to shorten the paths to fix the error
#
#	AF_UNIX path too long

# Create a container for the soflinks for this job
#export parrotCacheTMP=$(mktemp -d -p ${parrotCacheDailyRoot} .XXX)
#export parrotCacheTMP=$(mktemp -d -p ${parrotCacheUserRoot} .XXX)
export parrotCacheTMP=$(mktemp -d -p ${parrotRoot} tmpCache.XXX)

f_echo "TMP Redirection Cache     = ${parrotCacheTMP}"

# Create some defaults for these
[[ -z "${TMP}"    ]] && export TMP=${OSG_WN_TMP}
[[ -z "${TEMP}"   ]] && export TEMP=${OSG_WN_TMP}
[[ -z "${TMPDIR}" ]] && export TMPDIR=${OSG_WN_TMP}

# Redirect the path via a softlink saving the old for a restore later
OLD_TMP=${TMP}       ; export TMP=${parrotCacheTMP}/TMP       ; ln -s ${OLD_TMP}    ${TMP}
OLD_TEMP=${TEMP}     ; export TEMP=${parrotCacheTMP}/TEMP     ; ln -s ${OLD_TEMP}   ${TEMP}
OLD_TMPDIR=${TMPDIR} ; export TMPDIR=${parrotCacheTMP}/TMPDIR ; ln -s ${OLD_TMPDIR} ${TMPDIR}

#f_echo "Redirect TMP    to ${TMP}    from ${OLD_TMP}"
#f_echo "Redirect TEMP   to ${TEMP}   from ${OLD_TEMP}"
#f_echo "Redirect TMPDIR to ${TMPDIR} from ${OLD_TMPDIR}"


#########################################################################################
# And finally, are we Native or Run Parrot Run
#########################################################################################

f_echo

# Should we use Parrot or another way to access the CVMFS repositories

if [[ -z "${parrotUseParrotCVMFS}" ]]; then

  if [[ -n "${parrotUseNativeONLY}" ]]; then
    f_echo "Begin execution using Native CVMFS to access the repositories"
  elif [[ -n "${parrotUseNfsCVMFS}" ]]; then
    f_echo "Begin execution using nfsCVMFS to access the repositories"
  elif [[ -n "${parrotUsePortableCVMFS}" ]]; then
    f_echo "Begin execution using PortableCVMFS to access the repositories"
  fi

  echo "################################################################################"
  echo

  ${parrotHome}/exec.sh "$@"

  # Save the return code from the user job
  wrapperRet=$?

else

  if [[ -n "${parrotUseParrotChirp}" ]]; then
    f_echo "Begin execution within Parrot/Chirp ${parrotVersion} environment"
  else
    f_echo "Begin execution within Parrot/CVMFS ${parrotVersion} environment" 
  fi

  echo "################################################################################"
  echo


  # We redirect via --mount all bin, library, python and perl modules to the ACE Image

  if [[ -n "${parrotUseParrotMount}" ]]; then

    # Execute the command in a parrot-enabled bash subshell, mapping access into the ACE Image
    ${parrotBIN}/parrot_run								\
	--with-snapshots 								\
	--timeout 900									\
	--tempdir "${parrotCache}"							\
	--proxy   "${parrotProxy}"							\
        --mount /bin=${aceImage}/bin                                                    \
        --mount /sbin=${aceImage}/sbin                                                  \
        --mount /lib=${aceImage}/lib                                                    \
        --mount /lib64=${aceImage}/lib64                                                \
        --mount /opt=${aceImage}/opt                                                    \
        --mount /root=${aceImage}/root                                                  \
        --mount /usr=${aceImage}/usr                                                    \
        --mount /etc=${aceImage}/etc                                                    \
        --mount /etc/passwd=${aceEtc}/passwd                                            \
        --mount /etc/group=${aceEtc}/group                                              \
        --mount /etc/hosts=/etc/hosts                                                   \
        --mount /etc/resolv.conf=/etc/resolv.conf                                       \
	--mount /etc/fstab=/etc/fstab                                                   \
        --mount /etc/mtab=/etc/mtab                                                     \
        --mount /var=${aceVar}                                                          \
	--cvmfs-repo-switching 								\
	--cvmfs-repos "<default-repositories> ${cvmfsRepoList}"				\
        ${parrotRunCVMFS}								\
        ${parrotRunChirp}								\
		${parrotHome}/exec.sh "$@"

    # Save the return code from the user job
    wrapperRet=$?

  else

    # Execute the command in a parrot-enabled bash subshell 
    ${parrotBIN}/parrot_run								\
	--with-snapshots 								\
	--timeout 900									\
	--tempdir "${parrotCache}"							\
	--proxy   "${parrotProxy}"							\
	--cvmfs-repo-switching 								\
	--cvmfs-repos "<default-repositories> ${cvmfsRepoList}"				\
        ${parrotRunCVMFS}								\
        ${parrotRunChirp}								\
		${parrotHome}/exec.sh "$@"

    # Save the return code from the user job
    wrapperRet=$?

  fi
fi

#########################################################################################

echo
echo "################################################################################"


#########################################################################################
# Restore the original TMP paths
#########################################################################################

# Restore the old TMP paths and remove the softlinks

#f_echo "Restoring old values to TMP, TEMP and TMPDIR"

# Restore the old values
export TMP=${OLD_TMP}
export TEMP=${OLD_TEMP}
export TMPDIR=${OLD_TMPDIR}

# Remove the TMP softlinks cache dirctory
f_echo "Removing TMP Redirection Cache located at ${parrotCacheTMP}"
rm -rf ${parrotCacheTMP}


#########################################################################################
# If we used a private Parrot Cache, clean it up
#########################################################################################

# Remove the Per Job Private Cache

if [[ -n "${parrotUseCachePerJob}" ]]; then
  f_echo "Removing Private Parrot Cache located at ${parrotCache}"
  rm -rf ${parrotCache}
fi


#########################################################################################

f_echo "End of Parrot Wrapper Version ${parrotWrapperVersion}"

echo "################################################################################"

#########################################################################################

# Exit with the return code from the user job
exit ${wrapperRet}
