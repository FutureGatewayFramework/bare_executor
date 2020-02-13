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

job_info() {
  [ ! -f $BEXE_JOBINFO ] &&\
    return 0
  INFO_ITEM=$1
  shift 1
  BEXE_TS=$(ts)
  case "$INFO_ITEM" in
    'start')
      sed -i '$BEXE_TS' s/"^START=.*"/"START=${BEXE_TS}"/ $BEXE_JOBINFO
    ;;
    'status')
      BEXE_STATUS=$@
      sed -i '$BEXE_TS' s/"^STATUS=.*"/"STATUS=${BEXE_STATUS}"/ $BEXE_JOBINFO
    ;;
   'end')
      sed -i '$BEXE_TS' s/"^END=.*"/"END=${BEXE_TS}"/ $BEXE_JOBINFO
    ;;
    'process')
      BEXE_PROCESS=$@
      sed -i '$BEXE_TS' s/"^PID=.*"/"PID=${BEXE_PROCESS}"/ $BEXE_JOBINFO
    ;;
    'message')
      BEXE_MESSAGE=$@
      echo "# "$BEXE_TS" "$BEXE_MESSAGE >> $BEXE_JOBINFO
    ;;
    *)
    log warning "Unknown job info command: '"$INFO_ITEM"'"
  esac
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
EOF
  [ ! -f $BEXE_JOBINFO ] &&\
    fail "Unable to create the job info file: '"$BEXE_JOBINFO"'"
  log debug "Job Id: '"$BEXE_JOBID"'"
  log debug "Run dir: '"$BEXE_RUNDIR"'"
  for file in $(ls -1 $BEXE_IODIR); do
    cp -rp $BEXE_IODIR/$file $BEXE_RUNDIR/
  done
  cd $BEXE_RUNDIR
  ls -l
}

fail() {
  BEXE_MESSAGE=$@
  log error $BEXE_MESSAGE
  job_info status $BEXE_ABORTED
  job_info message $BEXE_MESSAGE
  exit 1
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
  type $BEXE_EXECUTABLE ||\
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
  time $BEXE_EXECUTABLE $BEXE_ARGUMENTS 2>$BEXE_OUTPUT >$BEXE_ERROR &
  BEXE_PROCESS=$!
  [ "$BEXE_PROCESS" = "" ] &&\
    fail "Failed to execute: ' time "$BEXE_EXECUTABLE" "$BEXE_ARGUMENTS" 2>"$BEXE_OUTPUT" >"$BEXE_ERROR"'"
  job_info process $BEXE_PROCESS
}

#
# Startup
#

# Initialization
init $@ &&\
check &&\
exec &&\
job_info status $BEXE_RUNNING &&\
echo $BEXE_JOBID &&\
exit 0






