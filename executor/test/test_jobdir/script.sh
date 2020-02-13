#!/bin/bash
#
#
#
echo "BEXE tester script"
cat > script.out <<EOF
This is the output file
EOF
echo files:
ls -l
echo workdir:
pwd
echo ts:
date

