#!/bin/bash -ex

# CMSSW_14_0_4

hltGetConfiguration run:378981 \
  --globaltag 140X_dataRun3_HLT_v3 \
  --data \
  --no-prescale \
  --output minimal \
  --max-events -1 \
  --input /store/group/tsg/FOG/debug/240405_run378981/files/run378981_ls0002_index000000_fu-c2b03-22-01_pid1720286.root \
  > hlt.py

cat <<@EOF >> hlt.py
process.options.wantSummary = True

process.options.numberOfThreads = 1
process.options.numberOfStreams = 0

process.options.accelerators = ["cpu"]

process.hltL1MuonNoL2SelectorNoVtx.L1MinPt = 0.001

if hasattr(process, 'MessageLogger'):
    del process.MessageLogger
process.load('FWCore.MessageLogger.MessageLogger_cfi')
@EOF

CUDA_LAUNCH_BLOCKING=1 \
cmsRun hlt.py &> hlt.log
