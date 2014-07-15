#!/bin/sh

# The CCTOOLS we are to use
#cctoolsVer="current"
cctoolsVer="4.2.0rc2"

# Override the default it given
[[ ! -z $1 ]] && cctoolsVer=$1

# Were we can find the cctools tarball
cctoolsHome=/home/www/parrot


# The pCVMFS we are to use
pcvmfsVer="2.1.19"

# Override the default it given
[[ ! -z $1 ]] && pcvmfsVer=$2

# Where we can find the pCVMFS tarball
pcvmfsHome=/home/www/parrot



# Additions to support CVMFS via parrot

function f_maketarball () {

  # Factory for which we are building this tarball
  factoryName=$1

  # CCTOOLS to use
  cctoolsVer=$2

  # Get a working temp directory
  tmpHome=$(mktemp -d)

  # Location where to build
  parrotHome="${tmpHome}/parrot"

  # Create all the directories we need
  mkdir -p ${parrotHome}

  # Untar the requested cctools version into the home area
  tar --extract --gzip --directory=${tmpHome} --file=${cctoolsHome}/cctools-${cctoolsVer}.tar.gz

  # Add a copy of the CVMFS public keys
  cp    ${buildHome}/cern.ch.pub                ${parrotHome}/cern.ch.pub
  cp    ${buildHome}/cern-it1.cern.ch.pub       ${parrotHome}/cern-it1.cern.ch.pub
  cp    ${buildHome}/cern-it2.cern.ch.pub       ${parrotHome}/cern-it2.cern.ch.pub
  cp    ${buildHome}/cern-it3.cern.ch.pub       ${parrotHome}/cern-it3.cern.ch.pub
  cp    ${buildHome}/osg.mwt2.org.pub           ${parrotHome}/osg.mwt2.org.pub

  # Parrot needs some support executables and libraries which might not exist at the target
  cp -r ${buildHome}/bin                        ${parrotHome}/bin
  cp -r ${buildHome}/lib                        ${parrotHome}/lib
  cp -r ${buildHome}/lib64                      ${parrotHome}/lib64
  cp -r ${buildHome}/python                     ${parrotHome}/python

  # Copy the CCTools products we need
  cp    ${tmpHome}/cctools/bin/parrot_run       ${parrotHome}/bin
  cp -r ${tmpHome}/cctools/lib/lib              ${parrotHome}
  cp -r ${tmpHome}/cctools/lib/lib64            ${parrotHome}

  # Untar the PortableCVMFS into the parrot Home area
  tar --extract --gzip --directory=${parrotHome} --file=${pcvmfsHome}/PortableCVMFS-${pcvmfsVer}.tar.gz

  # Copy over the $OSG_APP area
  cp -r ${buildHome}/OSG_APP                    ${parrotHome}/OSG_APP

  # Add a copy of the job wrappers
  cp ${buildHome}/functions.sh                  ${parrotHome}/functions.sh;      chmod 755 ${parrotHome}/functions.sh
  cp ${buildHome}/parrot_wrapper.sh             ${parrotHome}/parrot_wrapper.sh; chmod 755 ${parrotHome}/parrot_wrapper.sh
  cp ${buildHome}/setup_ace.sh                  ${parrotHome}/setup_ace.sh;      chmod 755 ${parrotHome}/setup_ace.sh
  cp ${buildHome}/setup_osg.sh                  ${parrotHome}/setup_osg.sh;      chmod 755 ${parrotHome}/setup_osg.sh
  cp ${buildHome}/setup_ca.sh                   ${parrotHome}/setup_ca.sh;       chmod 755 ${parrotHome}/setup_ca.sh
  cp ${buildHome}/setup_site.sh.$factoryName    ${parrotHome}/setup_site.sh;     chmod 755 ${parrotHome}/setup_site.sh
  cp ${buildHome}/exec.sh                       ${parrotHome}/exec.sh;           chmod 755 ${parrotHome}/exec.sh



  # Create the tarball
  tar --create --gzip --file=${tmpHome}/parrot.tar.gz --directory=${tmpHome} parrot


  # Put a copy in a place others can wget
  cp ${tmpHome}/parrot.tar.gz                     /home/www/parrot/parrot.tar.gz.${factoryName}

  # Destroy the working temp directory
  rm -rf ${tmpHome}

  echo "Built tarball with CCTOOLS ${cctoolsVer} for factory ${factoryName}"

}


# Where all our needed files should live
buildHome="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


# Make all the tarballs

f_maketarball generic        ${cctoolsVer}
f_maketarball icc            ${cctoolsVer}
f_maketarball icc_golub      ${cctoolsVer}
f_maketarball icc_hept3      ${cctoolsVer}
f_maketarball icc_mcore      ${cctoolsVer}
f_maketarball icc_taub       ${cctoolsVer}
f_maketarball midway         ${cctoolsVer}
f_maketarball midway_mcore   ${cctoolsVer}
f_maketarball odyssey        ${cctoolsVer}
f_maketarball stampede       ${cctoolsVer}
f_maketarball stampede_mcore ${cctoolsVer} 
f_maketarball uci            ${cctoolsVer}
f_maketarball utexas         ${cctoolsVer}
