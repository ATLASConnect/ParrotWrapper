#!/bin/bash

######################################################################################
# Functions definitions
######################################################################################

# Echo a line with the current date/time and the script who called

function f_echo () {

  _level=0
  _name="functions"


  # Find the first script not called "functions"

  while [[ "${_name}" == "functions" ]]; do
    _name=$(basename ${BASH_SOURCE[${_level}]} .sh)
    _level=$((_level+1))
    [[ ${_level} -gt 10 ]] && _name="*error*"
  done

  _date=$(date "+%d %b %H:%M:%S")
  _name=$(echo ${_name} | sed -e :a -e 's/^.\{1,15\}$/& /;ta')

  echo "${_date}| ${_name} | $@"

  return 0

}


# Set a ulimit value for a job with a default value

function f_ulimit () {

  _ulimitOPT=$1
  _ulimitDEF=$2
  _ulimitVAL=$3

  # If we have a preferred value, try to set it

  if [[ -n "${_ulimitVAL}" ]]; then
    ulimit -S ${_ulimitOPT} ${_ulimitVAL} 2>/dev/null
    _ulimitSTS=$?

    if [[ ${_ulimitSTS} -ne 0 ]]; then
      f_echo "Unable to set preferred ulimit ${_ulimitOPT} ${_ulimitVAL}"
    fi
  else
    _ulimitSTS=1
  fi


  # If we did not set a preferred value, try to set a default
  # If the default is "hard", use the Hard value

  if [[ ${_ulimitSTS} -ne 0 ]]; then

    [[ "${_ulimitDEF}" = "hard" ]] && _ulimitDEF=$(ulimit -H ${_ulimitOPT})

    ulimit -S ${_ulimitOPT} ${_ulimitDEF} 2>/dev/null
    _ulimitSTS=$?

    if [[ ${_ulimitSTS} -ne 0 ]]; then
      f_echo "Unable to set default ulimit ${_ulimitOPT} ${_ulimitDEF}"
      f_echo "Effective ulimit ${_ulimitOPT} $(ulimit -S ${_ulimitOPT})"
    fi
  fi

  return ${_ulimitSTS}

}


# Add a path to $PATH if it is missing

function f_addpath () {

  echo ${PATH} | /bin/egrep -q "(^|:)$1($|:)"

  if [[ $? -ne 0 ]]; then
    if [[ -z "${PATH}" ]]; then
      export PATH=$1
    else
      if [[ $2 == "^" ]]; then
        export PATH=$1:${PATH}
      else
        export PATH=${PATH}:$1
      fi
    fi
  fi

  return 0

}


# Add a path to $LD_LIBRARY_PATH if it is missing

function f_addldlibrarypath () {

  echo ${LD_LIBRARY_PATH} | /bin/egrep -q "(^|:)$1($|:)"

  if [[ $? -ne 0 ]]; then
    if [[ -z "${LD_LIBRARY_PATH}" ]]; then
      export LD_LIBRARY_PATH=$1
    else
      if [[ $2 == "^" ]]; then
        export LD_LIBRARY_PATH=$1:${LD_LIBRARY_PATH}
      else
        export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:$1
      fi
    fi
  fi

  return 0

}


# Create a lock on a given location

function f_create_lock () {

  # The area to lock
  _lockRoot=$1

  # Name of the lock
  _lockName=$2


  # Number of seconds before declaring a dead lock (60 minutes)
  _lockDead=$((60*60))

  # Number of seconds between retires
  _lockWait=15


  f_echo "Requesting a lock for ${_lockName}"

  # Request the lock
  ${parrotBIN}/lockfile -${_lockWait} -r $(((${_lockDead}/${_lockWait})+1)) -s $((2*${_lockWait})) -l ${_lockDead} ${_lockRoot}.lock 2>/dev/null

  # Save our status
  _lockStatus=$?

  # If we cannot get a lock, print out the error message and exit
  if [[ ${lockStatus} -ne 0 ]]; then
    f_echo
    f_echo "Unable to get a lock for ${_lockName} due to error ${_lockStatus}"
    f_echo
    return ${_lockStatus}
  fi

  # If this script exits, try to cleanup the lock on a sudden death
  trap "rm -f ${_lockRoot}.lock; return" ${parrotTRAP}

  f_echo "Lock granted for ${_lockName}"

  return 0

}


# Remove the lock on a given location

function f_remove_lock () {

  # The area to lock
  _lockRoot=$1

  # Name of the lock
  _lockName=$2


  # Remove the lock file
  rm -f ${_lockRoot}.lock

  f_echo "Releasing lock on ${_lockName}"

  # Clear out any traps since we have completed
  trap - ${parrotTRAP}

  return 0

}



# Determine if a given location should be updated

function f_update_lock () {

  # The location to update
  _updateRoot=$1

  # The TS file for this location
  _updateTS=$2

  # Name of the location we are attempting to update
  _updateName=$3


  # Check for a timestamp and get a lock if none present

  if [[ -f ${_updateTS} ]]; then
    # If there is a TimeStamp, no need to update
    _updateStatus=0
  else

    # No TimeStamp, we might need to update

    # Try to lock the location
    f_create_lock "${_updateRoot}" "${_updateName}"


    # See if we still need to update

    if [[ -f ${_updateTS} ]]; then

      # We now have a timestamp file, someone else did the update
      _updateStatus=0
      f_remove_lock "${_updateRoot}" "${_updateName}"

    else

       # No timestamp, so we must update the location
      _updateStatus=1

    fi
  fi

  # Return the update or not update status
  return ${_updateStatus}

}


# Return the time to the next update of a given location

function f_update_time () {

  # The time stamp file
  _tsFile=${1}

  # Window of time between updates in seconds
  _tsTime=$((${2}*60))


  # The time stamp file must exist or else we need an update

  if [[ -f ${_tsFile} ]]; then
    _tsDelta=$(($(date +%s) - $(cat ${_tsFile})))
    _tsUpdate=$((${_tsTime}-${_tsDelta}))
    [[ ${_tsUpdate} -le 0 ]] && _tsUpdate=0
    [[ ${_tsUpdate} -gt 0 ]] && _tsUpdate=1
  else
    _tsUpdate=0
  fi

  # Return if we should (0) or should not (1) update this location
  return ${_tsUpdate}

}


# Determine if a given location should be updated given a window of time

function f_update_lock_timed () {

  # The location to update
  _updateRoot=$1

  # The TS file for this location
  _updateTS=$2

  # The time window between updates
  _updateMin=$3

  # Name of the location we are attempting to update
  _updateName=$4


  # Check if we are outside the window of time for an update
  f_update_time "${_updateTS}" "${_updateMin}"

  # Save the return of should we or should we not update
  _updateStatus=$?


  # Do the update if so ordered

  if [[ ${_updateStatus} -eq 0 ]]; then

    # Try to lock the location
    f_create_lock "${_updateRoot}" "${_updateName}"

    # See if someone updated this loaction while we were waiting on the lock
    f_update_time "${_updateTS}" "${_updateMin}"

    # Again, should we or should we note update
    _updateStatus=$?

    # If no update is needed, remove the lock
    [[ ${_updateStatus} -ne 0 ]] && f_remove_lock "${_updateRoot}" "${_updateName}"

  fi

  # Return the update or not update status
  return ${_updateStatus}

}
