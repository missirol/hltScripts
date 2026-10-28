#!/bin/bash -ex

hltGetConfiguration /dev/CMSSW_14_0_0/GRun/V182 \
  --globaltag 140X_dataRun3_HLT_v3 --data --no-prescale --no-output \
  --input /store/data/Run2024I/EphemeralHLTPhysics0/RAW/v1/000/386/593/00000/91a08676-199e-404c-9957-f72772ef1354.root \
  --max-events 10 \
  > hlt.py

cat <<@EOF >> hlt.py
process.options.numberOfThreads = 1
process.options.numberOfStreams = 0
@EOF

rm -f callgrind.out.*

valgrind --tool=callgrind \
  cmsRun hlt.py &> hlt.log

callgrind_annotate \
  --tree=both --inclusive=yes \
  --auto=yes --show-percs=yes \
  callgrind.out.* \
  > tmp.txt
