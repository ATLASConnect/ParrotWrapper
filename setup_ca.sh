#!/bin/bash

#########################################################################################
#
# Setup or update the ACE Certificate Authority
#
#########################################################################################


#f_echo "Update of the Certificate Authority"


#########################################################################################
# The ACE CA resides in the ACE Cache User Root to be shared by all jobs of the same user
# We use "rsync" to copy from the MWT2 repo to pick up changes on the fly
# To prevent collisions, we lock other jobs to create an atomic update
#########################################################################################


# Master Certificate Authority (CA)
aceSrcCA=${parrotCVMFSaceCA}

# CA Time Stamp
aceCAts=${aceCA}/.acelastupdate

# CA Time Window between updates in minutes
aceCAmin=60


# How we will sync the parts within ACE
aceRsync="/usr/bin/rsync --quiet --delete --ignore-errors --archive --no-owner --chmod=Dugo=rwx,-s"


#########################################################################################

# Only install a Certificate Authority into the ACE Cache if we are not using a CVMFS copy

if [[ -n ${parrotUseCVMFSaceCA} ]]; then
  f_echo "Using CVMFS based ACE Certicate Authority from ${aceCA}"
else

  # Determinate if we need to update (or build) the Certificate Authority
  f_update_lock_timed "${aceCA}" "${aceCAts}" "${aceCAmin}" "ACE Certificate Authority"

  # Save the time window
  caStatus=$?

  # We only do an update if the timer has expired

  if [[ ${caStatus} -ne 0 ]]; then
    f_echo "Next update of ACE Certificate Authority after $(date -d @$(($(cat ${aceCAts})+$((${aceCAmin}*60)))) +%c)"
  else

    f_echo "Update of the ACE Certificate Authority from ${aceSrcCA}"
    f_echo "ACE Certificate Authority will be located at ${aceCA}"

    # Create the location for the CA
    mkdir -p ${aceCA}

    # Update the CA with the latest CRLs using Parrot so we have access to /cvmfs
    ${parrotBIN}/parrot_run								\
        --with-snapshots								\
        --timeout 900									\
        --tempdir "${parrotCache}"							\
        --proxy   "${parrotProxy}"							\
        --cvmfs-repo-switching								\
        --cvmfs-repos "<default-repositories> ${cvmfsRepoList}"				\
        ${parrotRunCVMFS}								\
        ${parrotRunChirp}								\
  		${aceRsync} ${aceSrcCA}/ ${aceCA} 2> /dev/null

    # Save the rsync return status
    caStatus=$?

    # Clear out a 23 which means we could not copy due to a permissions error
    [[ ${caStatus} -eq 23 ]] && caStatus=0

    # Did the rsync work

    if [[ ${caStatus} -eq 0 ]]; then

      # Update the time stamp
      echo $(date +%s) > ${aceCAts}

      # Remove the lock
      f_remove_lock "${aceCA}" "ACE Certificate Authority"

      f_echo "Update of the ACE Certificate Authority complete"

    else

      f_echo "RSYNC of the ACE Certificate Authority failed with error ${caStatus}"

      # Remove the partial image
      rm -rf ${aceCA}

      # Remove the lock so others can now try
      f_remove_lock "${aceCA}" "ACE Certificate Authority"

      # Return with the bad code
      return ${caStatus}

    fi
  fi
fi


#########################################################################################


#f_echo "Update of the Certificate Authority complete"


#########################################################################################

# Return the final status
return 0
