#!/bin/bash

# cmsrel CMSSW_13_0_5_patch1
# cd CMSSW_13_0_5_patch1/src
# cmsenv

if [ $# -eq 0 ] || ([ $1 != HLT1 ] && [ $1 != HLT2 ] && [ $1 != HLT3 ]); then
  printf "%s\n" ">> ERROR: first command-line argument must be 'HLT1', 'HLT2', or 'HLT3' !"
  exit 1
fi

JOBTAG="${1}"

INPUTF=/eos/cms/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/FOG/error_stream/run366497/run366497_ls0196_index000095_fu-c2b01-26-01_pid1955211.raw
[ $# -eq 1 ] || INPUTF="${2}"

hltConfigFromDB --runNumber 366469 > "${JOBTAG}".py

cat <<@EOF >> "${JOBTAG}".py
process.options.numberOfThreads = 1
process.options.numberOfStreams = 0
process.options.wantSummary = True

process.hltOnlineBeamSpotESProducer.timeThreshold = int(1e6)

del process.MessageLogger
process.load('FWCore.MessageService.MessageLogger_cfi')
process.MessageLogger.cerr.FwkReport.reportEvery = 1
process.MessageLogger.cerr.enableStatistics = False
process.MessageLogger.cerr.threshold = 'INFO'

process.options.SkipEvent = cms.untracked.vstring(
  'InvalidGlobalAlgBlkBxCollection',
  'ProductNotFound',
)
@EOF

if [ "${JOBTAG}" = HLT1 ]; then
  cat <<@EOF >> "${JOBTAG}".py
process.source.fileListMode = True
process.source.fileNames = [ "${INPUTF}" ]
@EOF

elif [ "${JOBTAG}" = HLT2 ]; then
  rm -f repacked.root
  rm -rf run000000 && mkdir run000000
  cmsRun /afs/cern.ch/work/m/missirol/public/fog/run366469_crashL1uGT/convertToEDM.py inputFiles="${INPUTF}" outputFile=repacked.root
  INPUTF=repacked.root

  cat <<@EOF >> "${JOBTAG}".py
process.source = cms.Source( "PoolSource",
  fileNames = cms.untracked.vstring("file:${INPUTF}"),
)
@EOF

elif [ "${JOBTAG}" = HLT3 ]; then
  rm -f repacked.root
  rm -rf run000000 && mkdir run000000
  cmsRun /afs/cern.ch/work/m/missirol/public/fog/run366469_crashL1uGT/convertToEDM.py inputFiles="${INPUTF}" outputFile=repacked.root
  INPUTF=repacked.root

  cat <<@EOF >> "${JOBTAG}".py
process.source = cms.Source( "PoolSource",
  fileNames = cms.untracked.vstring("file:${INPUTF}"),
  skipEvents = cms.untracked.uint32(53),
)
process.maxEvents.input = 1
@EOF
fi

rm -rf run000000 && mkdir run000000
cmsRun "${JOBTAG}".py &> "${JOBTAG}".log
