#!/bin/bash

#########################################################################################
#
# Setup the Atlas Compliant Environment (ACE)
#
#########################################################################################


#f_echo "Update of the Atlas Compliant Environment"


#########################################################################################
# We need to make a shared copy of the Atlas Compliant Environment (ACE)
# The ACE resides in the ACE Cache User Root to be shared by all jobs of the same user
# We use "wget" to fetch all tarballs from the RCCF server
# To prevent collisions, we lock other jobs to create an atomic update
#########################################################################################

# The server with all our tarballs
aceHTTP=http://rccf.usatlas.org

# ACE Image tarball
aceImageTB=ace.tar.gz

# ACE OSG Worker Node Client (WNC) tarball
aceWNCtb=osg-wn-client.tar.gz


# ACE library path
aceImageLIB="${aceImage}/usr/lib64:${aceImage}/lib64:${aceImage}/usr/lib:${aceImage}/lib"

# ACE binary path
aceImageBIN="${aceImage}/usr/bin:${aceImage}/bin:${aceImage}/usr/sbin:${aceImage}/sbin"

# ACE python libraries path
aceImagePython="${aceImage}/usr/lib64/python2.6/site-packages:${aceImage}/usr/lib/python2.6/site-packages"

# ACE perl modules path
aceImagePerl="${aceImage}/usr/share/perl5/vendor_perl:${aceImage}/usr/share/perl5"



# ACE Time Stamp
aceImageTS=${aceImage}/.acelastupdate

# ACE etc Time Stamp
aceEtcTS=${aceEtc}/.acelastupdate

# ACE var Time Stamp
aceVarTS=${aceVar}/.acelastupdate

# WNC Time Stamp
aceWNCts=${aceWNC}/.acelastupdate

# How we will sync the parts within ACE
aceRsync="/usr/bin/rsync --quiet --delete --ignore-errors --archive --no-owner --chmod=Dugo=rwx,-s"


#########################################################################################
# Use an ACE Image from /cvmfs or from a TarBall copied into the ACE Cache
#########################################################################################

# If we are using a CVMFS Image, we are done

if [[ -n "${parrotUseCVMFSaceImage}" ]]; then
  f_echo "Using CVMFS based ACE Image from ${aceImage}"
else

  # Check to see if we need to update this area and get a lock if so 
  f_update_lock "${aceImage}" "${aceImageTS}" "ACE Image"

  # Save the status
  aceStatus=$?


  # Do we need to update this location

  if [[ ${aceStatus} -eq 0 ]]; then
    f_echo "Using existing ACE Image created on $(date -d @$(cat ${aceImageTS}) +%c)"
  else

    f_echo "Installation of the ACE Image from TarBall ${aceHTTP}/${aceImageTB}"
    f_echo "ACE Image will be located at ${aceImage}"

    # Remove any partial ACE that might be corrupt and start from scratch
    rm -rf ${aceImage}

    # Create the location for the ACE Image copy
    mkdir -p ${aceImage}

    # Pull down the current tarball from the osg area
    wget --quiet --directory-prefix=${aceImage} ${aceHTTP}/ace/${aceImageTB}

    # Save the status
    aceStatus=$?

    # Success or fail

    if [[ ${aceStatus} -ne 0 ]]; then
      f_echo "Unable to fetch the ACE Image TarBall with error ${aceStatus}"
    else

      # Unpack the ACE Image tarball into that location
      tar --extract --gzip --directory=${aceImage} --file=${aceImage}/${aceImageTB}

      # Save the tar status 
      aceStatus=$?

      # Success or fail

      if [[ ${aceStatus} -ne 0 ]]; then
        f_echo "Unable to install the ACE Image with error ${aceStatus}"
      else

        # Since we unpacked successfully, purge the tarball
        rm -f ${aceImage}/${aceImageTB}

        # Update the time stamp
        echo $(date +%s) > ${aceImageTS}

        # Completed successfully
        aceStatus=0

        f_echo "Installation of the ACE Image complete"

      fi
    fi


    # Success or failure of ACE Image installation

    if [[ ${aceStatus} -eq 0 ]]; then

      # ACE Image installed so we can remove the lock
      f_remove_lock "${aceImage}" "ACE Image"

    else

      # Remove the partial image
      rm -rf ${aceImage}

      # Remove the lock so others can now try
      f_remove_lock "${aceImage}" "ACE Image"

      # Return with the bad code
      return ${aceStatus}

    fi
  fi
fi


#########################################################################################
# If Parrot is not to be used, add all the ACE Image paths to ours
#########################################################################################


# If we are not using Parrot, we must add the ACE Image to the various paths

if [[ -z "${parrotUseParrotCVMFS}" ]]; then

  # Add the ACE Image Libraries
  if [[ -z "${LD_LIBRARY_PATH}" ]]; then
    export LD_LIBRARY_PATH="${aceImageLIB}"
  else
    export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${aceImageLIB}"
  fi

  # Add the ACE Image binaries to the end of the path
  if [[ -z "${PATH}" ]]; then
    export PATH="${aceImageBIN}"
  else
    export PATH="${PATH}:${aceImageBIN}"
  fi

  # Add the ACE Image Python modules
  if [[ -z "${PYTHONPATH}" ]]; then
    export PYTHONPATH="${aceImagePython}"
  else
    export PYTHONPATH="${PYTHONPATH}:${aceImagePython}"
  fi

  # Add the ACE Image Perl modules
  if [[ -z "${PERL5LIB-}" ]]; then
    export PERL5LIB="${aceImagePerl}"
  else
    export PERL5LIB="${PERL5LIB}:${aceImagePerl}"
  fi

fi



#########################################################################################
# Create the ACE etc (passwd, group)
#########################################################################################


# We only need an ACE etc if we are using Parrot to access /cvmfs

if [[ -n "${parrotUseParrotCVMFS}" ]]; then

  # Check to see if we need to update this area and get a lock if so 
  f_update_lock "${aceEtc}" "${aceEtcTS}" "ACE etc"
 
  # Save the status
  aceStatus=$?


  # Do we need to update this location

  if [[ ${aceStatus} -eq 0 ]]; then
    f_echo "Using existing ACE etc created on $(date -d @$(cat ${aceEtcTS}) +%c)"
  else

    f_echo "Installation of the ACE etc from ACE Image at ${aceImage}"
    f_echo "ACE etc will be located at ${aceEtc}"

    # Remove any partial ACE etc that might be corrupt and start from scratch
    rm -rf ${aceEtc}

    # Create the location for the ACE etc
    mkdir -p ${aceEtc}


    # If we are using the Image from /cvmfs, we must use Parrot/CVMFS to access the source files

    if [[ -n "${parrotUseCVMFSaceImage}" ]]; then

      # Use Parrot to fetch a copy of the etc directory
      ${parrotBIN}/parrot_run						\
	--with-snapshots						\
	--timeout 900							\
	--tempdir "${parrotCache}"					\
	--proxy   "${parrotProxy}"					\
	--cvmfs-repo-switching						\
	--cvmfs-repos "<default-repositories> ${cvmfsRepoList}"		\
	${parrotRunCVMFS}						\
	${parrotRunChirp}						\
		${aceRsync} ${aceImage}/etc/   ${aceEtc}   2>/dev/null

      # Save the rsync return status
      etcStatus=$?

    else

      # Make a copy of the "etc" in the ACE Image (directories only) into a writable location
      ${aceRsync} ${aceImage}/etc/   ${aceEtc}   2>/dev/null

      # Save the rsync return status
      etcStatus=$?

    fi


    # Clear out a 23 which means we could not copy due to a permissions error
    [[ ${etcStatus} -eq 23 ]] && etcStatus=0


    # Did we setup the ACE etc

    if [[ ${etcStatus} -eq 0 ]]; then

      # Append the local user and group
      echo "$(id -un):x:$(id -u):$(id -g)::${HOME}:/sbin/nologin" >> ${aceEtc}/passwd
      echo "$(id -gn):x:$(id -g):"                                >> ${aceEtc}/group

      # Update the time stamp
      echo $(date +%s) > ${aceEtcTS}

      # ACE etc installed so we can remove the lock
      f_remove_lock "${aceEtc}" "ACE etc"

      f_echo "Installation of the ACE etc complete"

    else

      f_echo "RSYNC of the ACE etc failed with error ${etcStatus}"

      # Remove the partial image
      rm -rf ${aceEtc}

      # Clean the lock to allow the next guy to try again
      f_remove_lock "${aceEtc}" "ACE etc"

    fi
  fi
fi


#########################################################################################
# Create the ACE var in a writable area since the ACE Image many be read only
#########################################################################################


# We only need an ACE var if we are using Parrot to access /cvmfs

if [[ -n "${parrotUseParrotCVMFS}" ]]; then

  # Check to see if we need to update this area and get a lock if so 
  f_update_lock "${aceVar}" "${aceVarTS}" "ACE var"
 
  # Save the status
  aceStatus=$?


  # Do we need to update this location

  if [[ ${aceStatus} -eq 0 ]]; then
    f_echo "Using existing ACE var created on $(date -d @$(cat ${aceVarTS}) +%c)"
  else

    f_echo "Installation of the ACE var from ACE Image at ${aceImage}"
    f_echo "ACE var will be located at ${aceVar}"

    # Remove any partial ACE var that might be corrupt and start from scratch
    rm -rf ${aceVar}
  
    # Create the location for the ACE var
    mkdir -p ${aceVar}


    # If we are using the Image from /cvmfs, we must use Parrot/CVMFS to access the source files

    if [[ -n "${parrotUseCVMFSaceImage}" ]]; then

      # Use Parrot to fetch a copy of the var directory
      ${parrotBIN}/parrot_run					\
	--with-snapshots						\
	--timeout 900							\
	--tempdir "${parrotCache}"					\
	--proxy   "${parrotProxy}"					\
	--cvmfs-repo-switching						\
	--cvmfs-repos "<default-repositories> ${cvmfsRepoList}"		\
	${parrotRunCVMFS}						\
	${parrotRunChirp}						\
		${aceRsync} --filter="+ */" --filter="- *"   ${aceImage}/var/   ${aceVar}   2>/dev/null

      # Save the rsync return status
      varStatus=$?

    else

      # Make a copy of the "var" in the ACE Image (directories only) into a writable location
      ${aceRsync} --filter="+ */" --filter="- *"   ${aceImage}/var/   ${aceVar}   2>/dev/null

      # Save the rsync return status
      varStatus=$?

    fi


    # Clear out a 23 which means we could not copy due to a permissions error
    [[ ${varStatus} -eq 23 ]] && varStatus=0

    # Did the rsync work

    if [[ ${varStatus} -eq 0 ]]; then

      # Update the time stamp
      echo $(date +%s) > ${aceVarTS}

      # ACE var installed so we can remove the lock
      f_remove_lock "${aceVar}" "ACE var"

      f_echo "Installation of the ACE var complete"

    else

      f_echo "RSYNC of the ACE var failed with error ${varStatus}"

      # Remove the partial image
      rm -rf ${aceVar}

      # Clean the lock to allow the next guy to try again
      f_remove_lock "${aceVar}" "ACE var"

      # Return with the bad code
      return ${varStatus}

    fi
  fi
fi


#########################################################################################
# Build a copy of the OSG WN Client in the ACE Cache
#########################################################################################

# Only install an OSG WNC Client into the ACE Cache if we are not to use CVMFS

if [[ -n "${parrotUseCVMFSaceWNC}" ]]; then
  f_echo "Using CVMFS based OSG WN Client from ${aceWNC}/osg-wn-client"
else

  # Check to see if we need to update this area and get a lock if so 
  f_update_lock "${aceWNC}" "${aceWNCts}" "OSG WN Client"
 
  # Save the status
  aceStatus=$?


  # Do we need to update this location

  if [[ ${aceStatus} -eq 0 ]]; then
    f_echo "Using existing OSG WN Client created on $(date -d @$(cat ${aceWNCts}) +%c)"
  else

    f_echo "Installation of the OSG WN Client from TarBall ${aceHTTP}/${aceWNCtb}"
    f_echo "OSG WN Client will be located at ${aceWNC}"

    # Remove any partial WNC that might be corrupt and start from scratch
    rm -rf ${aceWNC}

    # Create the location for the OSG WN Client
    mkdir -p ${aceWNC}

    # Pull down the current tarball from the osg area
    wget --quiet --directory-prefix=${aceWNC} ${aceHTTP}/osg/${aceWNCtb}

    # Save the status
    wncStatus=$?

    # Success or fail

    if [[ ${wncStatus} -ne 0 ]]; then
      f_echo "Unable to fetch the OSG WN Client tarball with error ${wncStatus}"
    else
    
      # Unpack the OSG WN Client tarball into that location
      tar --extract --gzip --directory=${aceWNC} --file=${aceWNC}/${aceWNCtb}

      # Save the tar status 
      wncStatus=$?

      # Success or fail

      if [[ ${wncStatus} -ne 0 ]]; then
        f_echo "Unable to install the OSG WN Client with error ${wncStatus}"
      else

        # Since we unpacked successfully, purge the tarball
        rm -f ${aceWNC}/${aceWNCtb}

        # Do the post install to create the setup file
        ${aceWNC}/osg-wn-client/osg/osg-post-install >/dev/null

        # Update the time stamp
        echo $(date +%s) > ${aceWNCts}

        # Completed successfully
        wncStatus=0

      fi  
    fi


    # Success or failure to install OSG WN Client

    if [[ ${wncStatus} -eq 0 ]]; then

      # OSG WN Client installed so we can remove the lock
      f_remove_lock "${aceWNC}" "OSG WN Client"

    else

      # Remove any copy so we can try again later
      rm -rf ${aceWNC}

      # Clean the lock to allow the next guy to try again
      f_remove_lock "${aceWNC}" "OSG WN Client"

      # Return the failed code
      return ${wncStatus}

    fi


    # Last minute patches to OSG WN Client

    # Link in the CA we brought in above
    rm -rf ${aceWNC}/etc/grid-security/certificates
    ln -s  ${aceCA}/certificates ${aceWNC}/osg-wn-client/etc/grid-security/certificates

    f_echo "Installation of the OSG WN Client complete"

  fi
fi


#########################################################################################


#f_echo "Update of the Atlas Compliant Environment complete"


#########################################################################################

# Return with success
return 0
