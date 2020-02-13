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