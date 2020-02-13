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

init() {
  log debug "Starting execution"
  BEXE_IODIR=$1
  BEXE_TS=$(ts)
  BEXE_RUNDIR=$(mktemp -d $BEXE_HOME/${BEXE_TS}_${BEXE_JOBPREFIX}_XXXXXXXX)
  BEXE_JOBID=$(basename $BEXE_RUNDIR)
  BEXE_JOBINFO=$BEXE_RUNDIR/$BEXE_JOBINFO
  cat > $BEXE_JOBINFO <<EOF
START=${BEXE_TS}
STATUS=${BEXE_PROCESSING}
END=unknown
PID=unknown
RETCODE=unknown
EOF
  [ ! -f $BEXE_JOBINFO ] &&\
    fail "Unable to create the job info file: '"$BEXE_JOBINFO"'"
  log debug "Job Id: '"$BEXE_JOBID"'"
  log debug "Run dir: '"$BEXE_RUNDIR"'"
  for file in $(ls -1 $BEXE_IODIR); do
    cp -rp $BEXE_IODIR/$file $BEXE_RUNDIR/
  done
  cd $BEXE_RUNDIR
}

check() {
  # Check home directory exists
  [ ! -d "$BEXE_HOME" ] &&\
    fail "Invalid HOME directory: '"$BEXE_HOME"'" ||\
    log debug "Home dir: '"$BEXE_HOME"'"

  # Check passed IO directory exists
  [ "$BEXE_IODIR" = "" -o ! -d "$BEXE_IODIR" ] &&\
    fail "Invalid IO directory: '"$BEXE_IODIR"'" ||\
    log debug "Home IO dir: '"$BEXE_IODIR"'"

  # Check job descriptor
  [ ! -f "$BEXE_JOBDESC" ] &&\
    fail "Job descriptor file not existing" ||\
    log debug "Job file descriptor: '"$BEXE_JOBDESC"'"

  # Extract and check job description items
  # Job description must have the following structure:
  #
  #  { "executable": "/bin/bash", 
  #    "arguments": [ "script.sh", "arg1", "arg 2", "arg 3" ],
  #    "output": "output.txt",
  #    "error": "error.txt",
  #    "output_files": [ "script.out" ]}
  #

  # Executable
  BEXE_EXECUTABLE=$(cat $BEXE_JOBDESC | jq -e '.executable')
  BEXE_RES=$?
  [ $BEXE_RES -ne 0 ] &&\
    fail "Executable not specified in the job description file: '"$BEXE_JOBDESC"'"
  BEXE_EXECUTABLE=$(echo $BEXE_EXECUTABLE | xargs echo)
  type $BEXE_EXECUTABLE >>/dev/null ||\
    fail "Invalid job executable '"$BEXE_EXECUTABLE"'"
  job_info message "Executable: '"$BEXE_EXECUTABLE"'"
  # Arguments
  BEXE_ARGUMENTS=$(cat $BEXE_JOBDESC | jq -e '.arguments[]')
  BEXE_RES=$?
  [ $BEXE_RES -ne 0 ] &&\
    log warning "Keyword 'arguments' not specified in the job description file: '"$BEXE_JOBDESC"'" &&\
    BEXE_ARGUMENTS=""
  job_info message "Arguments: '"$BEXE_ARGUMENTS"'"
  # Output
  BEXE_OUTPUT=$(cat $BEXE_JOBDESC | jq -e '.output')
  BEXE_RES=$?
  [ $BEXE_RES -ne 0 ] &&\
    log warning "Keyword 'output' not specified in the job description file: '"$BEXE_JOBDESC"'" &&\
    BEXE_OUTPUT="$BEXE_JOBID".out
  BEXE_OUTPUT=$(echo $BEXE_OUTPUT | xargs echo)
  job_info message "Output: '"$BEXE_OUTPUT"'"
  # Error
  BEXE_ERROR=$(cat $BEXE_JOBDESC | jq -e '.error')
  BEXE_RES=$?
  [ $BEXE_RES -ne 0 ] &&\
    log warning "Keyword 'error' not specified in the job description file: '"$BEXE_JOBDESC"'" &&\
    BEXE_ERROR="$BEXE_JOBID".err
  BEXE_ERROR=$(echo $BEXE_ERROR | xargs echo)
  job_info message "Error: '"$BEXE_ERROR"'"
  # Ouput files
  BEXE_OUTPUT_FILES=$(cat $BEXE_JOBDESC | jq -e '.output_files[]')
  BEXE_RES=$?
  [ $BEXE_RES -ne 0 ] &&\
    log warning "Keyword 'output_files' not specified in the job description file: '"$BEXE_JOBDESC"'" &&\
    BEXE_OUTPUT_FILES=""
  job_info message "Output_file: '"$BEXE_OUTPUT_FILES"'"
}

exec() {
  # Perform execution
  chmod +x $BEXE_EXECUTABLE
  $BEXE_EXECUTABLE $BEXE_ARGUMENTS 2>$BEXE_OUTPUT >$BEXE_ERROR &
  BEXE_PROCESS=$!
  [ "$BEXE_PROCESS" = "" ] &&\
    fail "Failed to execute: ' time "$BEXE_EXECUTABLE" "$BEXE_ARGUMENTS" 2>"$BEXE_OUTPUT" >"$BEXE_ERROR"'"
  job_info process $BEXE_PROCESS
}

#
# Startup
#

init $@ &&\
check &&\
exec &&\
job_info status $BEXE_RUNNING &&\
echo $BEXE_JOBID &&\
exit 0






