#!/bin/bash
#
# Bare executor daemon
#
. bare_config.sh

# Cleanup
trap cleanup exit

# Cleanup function
cleanup() {
  job_info end $(ts)
}

check() {
  log debug "Starting check"
  BEXE_JOBID=$1
  BEXE_JOBDIR=$BEXE_HOME"/"$BEXE_JOBID

  # Check home directory exists
  [ ! -d "$BEXE_HOME" ] &&\
    fail "Invalid HOME directory: '"$BEXE_HOME"'" ||\
    log debug "Home dir: '"$BEXE_HOME"'"

  # Check passed IO directory exists
  [ ! -d "$BEXE_JOBDIR" ] &&\
    fail "Did not found job directory: '"$BEXE_JOBDIR"'" ||\
    log debug "Job dir: '"$BEXE_JOBDIR"'"

  # Check job info file
  [ ! -f "$BEXE_JOBDIR"/"$BEXE_JOBINFO" ] &&\
    fail "Did not found job info file: '"$BEXE_JOBDIR"/"$BEXE_JOBINFO"'" ||\
    log debug "Job info file: '"$BEXE_JOBDIR"/"$BEXE_JOBINFO"'"

  # Extract PID
  BEXE_PID=$(cat $BEXE_JOBDIR"/"$BEXE_JOBINFO | grep PID | awk -F'=' '{ print $2 }')
}

status() {
  kill -0 $BEXE_PID 2>/dev/null >/dev/null
  BEXE_KILLRES=$?
  [ $BEXE_KILLRES -eq 0 ] &&\
    BEXE_STATUS=$BEXE_RUNNING ||\
    BEXE_STATUS=$BEXE_DONE
  wait $BEXE_PID 2>/dev/null >/dev/null
  BEXE_RETCODE=$?
  [ $BEXE_RETCODE != 0 ] &&\
    BEXE_MESSAGE="Return code: $BEXE_RETCODE" &&\
    job_info retcode $BEXE_RETCODE &&\
    log warning $BEXE_MESSAGE
  job_info status $BEXE_STATUS
  echo "$BEXE_STATUS ($BEXE_RETCODE)"
}

#
# Startup
#

check $@ &&\
status