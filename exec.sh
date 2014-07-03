#!/bin/bash

# We are now in the environment that we want the job to run in
# We can now make any last second additions to the job


# Begin our journey from home
cd $HOME


# If no command was given to run, default to bash
# Otherwise, execute the given command line

if [[ -z "$@" ]]; then
  exec "bash"
else
  exec "$@"
fi
