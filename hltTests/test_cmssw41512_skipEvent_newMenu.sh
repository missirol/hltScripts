#!/bin/bash

# cmsrel CMSSW_13_0_5_patch1
# cd CMSSW_13_0_5_patch1/src
# cmsenv

JOBTAG=hlt_skipEvent_newMenu

INPUTDIR=/eos/cms/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/FOG/error_stream/run366

hltConfigFromDB --configName --adg /cdaq/test/missirol/test/2023/week18/CMSLITOPS_411/Test01/HLT > "${JOBTAG}".py

for dirPath in $(ls -d "${INPUTDIR}"*); do
  runNumber="${dirPath: -6}"
  cp "${JOBTAG}".py "${JOBTAG}"_run"${runNumber}".py
  cat <<EOF >> "${JOBTAG}"_run"${runNumber}".py
process.options.numberOfThreads = 1
process.options.numberOfStreams = 0
process.options.wantSummary = True

process.hltOnlineBeamSpotESProducer.timeThreshold = int(1e6)

del process.MessageLogger
process.load('FWCore.MessageService.MessageLogger_cfi')

import glob
process.source.fileListMode = True
process.source.fileNames = sorted(glob.glob("${dirPath}/*raw"))

process.EvFDaqDirector.runNumber = ${runNumber}
EOF
  rm -rf run"${runNumber}"
  mkdir run"${runNumber}"
  echo run"${runNumber}" ..
  cmsRun "${JOBTAG}"_run"${runNumber}".py &> "${JOBTAG}"_run"${runNumber}".log
  unset runNumber
done
unset dirPath
