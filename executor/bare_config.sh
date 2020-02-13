#!/bin/bash
#
# Bare executor configuraition settings
#

# Execution statuses
BEXE_PROCESSING="processing"
BEXE_RUNNING="running"
BEXE_ABORTED="aborted"
BEXE_DONE="done"

# Directory used to execute commands
BEXE_HOME=/tmp
BEXE_JOBPREFIX=bexe
BEXE_JOBDESC=bexe.json
BEXE_JOBINFO=.bexe

# User allowed to execute commands
BEXE_USER=$(whoami)

# Bare executor log direcory
BEXE_LOG=/tmp/bare_executor.log

#
# Bare executor helper functions
#
ts() {
  date +%Y%M%d%H%M%S
}

log() {
  TS=$(date +%Y%M%d%H%M%S)
  LOG_MODE=$1
  shift 1
  case "$LOG_MODE" in
    'debug')
        echo "$TS [debug]: $@" >> $BEXE_LOG
    ;;
    'error')
        echo "$TS [error]: $@" >> $BEXE_LOG
    ;;

    'warning')
        echo "$TS [warning]: $@" >> $BEXE_LOG
    ;;

    'output')
        echo "$TS [debug]: $@" >> $BEXE_LOG
    ;;
    *)
  esac
}

fail() {
  BEXE_MESSAGE=$@
  log error $BEXE_MESSAGE
  job_info status $BEXE_ABORTED
  job_info message $BEXE_MESSAGE
  exit 1
}

job_info() {
  [ ! -f $BEXE_JOBINFO ] &&\
    return 0
  INFO_ITEM=$1
  shift 1
  BEXE_TS=$(ts)
  case "$INFO_ITEM" in
    'start')
      sed -i.prev s/"^START=.*"/"START=${BEXE_TS}"/ $BEXE_JOBINFO
    ;;
    'status')
      BEXE_STATUS=$@
      sed -i.prev s/"^STATUS=.*"/"STATUS=${BEXE_STATUS}"/ $BEXE_JOBINFO
    ;;
   'end')
      sed -i.prev s/"^END=.*"/"END=${BEXE_TS}"/ $BEXE_JOBINFO
    ;;
    'process')
      BEXE_PROCESS=$@
      sed -i.prev s/"^PID=.*"/"PID=${BEXE_PROCESS}"/ $BEXE_JOBINFO
    ;;
    'retcode')
      BEXE_RETCODE=$@
      sed -i.prev s/"^RETCODE=.*"/"RETCODE=${BEXE_RETCODE}"/ $BEXE_JOBINFO
    ;;
    'message')
      BEXE_MESSAGE=$@
      echo "# "$BEXE_TS" "$BEXE_MESSAGE >> $BEXE_JOBINFO
    ;;
    *)
    log warning "Unknown job info command: '"$INFO_ITEM"'"
  esac
  rm -f "$BEXE_JOBINFO".prev
}
