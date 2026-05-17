#!/bin/bash

hltLabel=hlt
[ $# -lt 1 ] || hltLabel="${1}"

https_proxy=http://cmsproxy.cms:3128/ \
hltGetConfiguration run:386917 \
  --input root://eoscms.cern.ch//eos/cms/store/group/tsg/FOG/debug/241014_run386917/hlt-slow-event/run386917_ls0306_index000115.root \
  --data \
  --globaltag 140X_dataRun3_HLT_v3 \
  --no-output \
  --no-prescale \
  --max-events 1 \
  --timing \
  --path HLT_Mu20NoFiltersNoVtxDisplaced_Photon20_CaloCustomId_v* \
  > "${hltLabel}".py

cat <<@EOF >> "${hltLabel}".py
del process.MessageLogger
process.load("FWCore.MessageLogger.MessageLogger_cfi")

process.source.skipEvents = cms.untracked.uint32( 91 )

process.options.numberOfThreads = 1
process.options.numberOfStreams = 0

#process.hltL3NoFiltersNoVtxTrajSeedIOHit.TkSeedGenerator.iterativeTSG.firstTSG.OrderedHitsFactoryPSet.GeneratorPSet.maxElement = 50000
#process.hltL3NoFiltersNoVtxTrajSeedIOHit.TkSeedGenerator.iterativeTSG.secondTSG.OrderedHitsFactoryPSet.maxElement = 180000

#process.hltL3NoFiltersNoVtxTrajSeedIOHit.TrackerSeedCleaner.cleanerFromSharedHits = False
@EOF

cmsRun "${hltLabel}".py #&> "${hltLabel}".log
