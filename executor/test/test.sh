#!/bin/bash
cd ..
JOBID=$(./bare_exec.sh $(pwd)/test/test_jobdir)
[ "$JOBID" != "" ] &&\
  ./bare_status.sh $JOBID 
cd - >>/dev/null
