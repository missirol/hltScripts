#!/bin/bash -x

# Tested with CMSSW_16_0_0_pre4

hltGetConfiguration \
  /dev/CMSSW_16_0_0/GRun/V5 \
  --globaltag 150X_dataRun3_HLT_v1 \
  --data \
  --no-prescale \
  --no-output \
  --max-events 100 \
  --paths DQM_Pixel* \
  --input /store/group/tsg/FOG/error_stream_root/run398308/run398308_ls0169_index000384_fu-c2b14-17-01_pid4164345.root \
  > hlt.py

cat <<@EOF >> hlt.py
process.options.wantSummary = False
process.options.numberOfThreads = 1
process.options.numberOfStreams = 0

#process.hltSiPixelClustersSoA.DoDigiMorphing = False
#process.hltSiPixelClustersSoASerialSync.DoDigiMorphing = False
@EOF

cmsRun hlt.py &> hlt.log

compute-sanitizer --tool=racecheck --racecheck-report=all \
cmsRun hlt.py &> hlt_racecheck.log

compute-sanitizer --tool=memcheck \
cmsRun hlt.py &> hlt_memcheck.log

compute-sanitizer --tool=initcheck \
cmsRun hlt.py &> hlt_initcheck.log

compute-sanitizer --tool=synccheck \
cmsRun hlt.py &> hlt_synccheck.log
