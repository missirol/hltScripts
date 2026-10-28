#!/bin/bash -ex

# https://github.com/cms-sw/cmssw/issues/43078

hltGetConfiguration run:388419 \
  --globaltag 141X_dataRun3_HLT_v1 \
  --data \
  --no-prescale \
  --no-output \
  --max-events 1 \
  --input root://eoscms.cern.ch//eos/cms/store/group/tsg/FOG/error_stream_root/run388419/run388419_ls1071_index000277_fu-c2b04-39-01_pid1780117.root \
  > hlt.py

cat <<@EOF >> hlt.py
process.options.wantSummary = True
process.options.numberOfThreads = 1
process.options.numberOfStreams = 0

process.source.skipEvents = cms.untracked.uint32( 37 )
#
#del process.MessageLogger
#process.load('FWCore.MessageLogger.MessageLogger_cfi')
#
#process.options.accelerators = ['cpu']
@EOF

cmsRun hlt.py &> hlt.log
