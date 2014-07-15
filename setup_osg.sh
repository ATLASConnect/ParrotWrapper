#!/bin/bash

#########################################################################################
#
# Setup the Atlas Compliant Environment (ACE) OSG WN Client
#
#########################################################################################
#
# We need to make a shared copy of the Atlas Compliant Environment (ACE) OSG WN Client
# The ACE resides in the ACE Cache User Root to be shared by all jobs of the same user
# We use "wget" to fetch all tarballs from the RCCF server
# To prevent collisions, we lock other jobs to create an atomic update
#
#########################################################################################

# The server with all our tarballs
aceHTTP=http://rccf.usatlas.org


# ACE OSG Worker Node Client (WNC) tarball
aceWNCtb=osg-wn-client.tar.gz


# WNC Time Stamp
aceWNCts=${aceWNC}/.acelastupdate


#########################################################################################
# Build a copy of the OSG WN Client in the ACE Cache
#########################################################################################

# Only install an OSG WNC Client into the ACE Cache if we are not to use CVMFS

if [[ -z "${parrotUseCVMFSaceWNCtb}" ]]; then
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

# Return with success
return 0
