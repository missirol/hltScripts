#!/bin/bash

run(){

  https_proxy=http://cmsproxy.cms:3128/ \
  hltGetConfiguration "${2}" \
    --globaltag 140X_dataRun3_HLT_v3 \
    --data \
    --unprescale \
    --output minimal \
    --max-events 300 \
    --eras Run3_2024 --l1-emulator uGT --l1 L1Menu_CollisionsHeavyIons2023_v1_1_5_xml \
    --paths HLT_HIL3DoubleMu0_M2to4p5_Open_v* \
    --input root://eoscms.cern.ch//eos/cms/store/user/cmsbuild/store/data/Run2023D/EphemeralHLTPhysics0/RAW/v1/000/370/293/00000/2ef73d2a-1fb7-4dac-9961-149525f9e887.root \
    > "${1}".py

  cat <<@EOF >> "${1}".py

process.options.numberOfThreads = 1
process.options.numberOfStreams = 0

process.source.eventsToProcess = cms.untracked.VEventRange('370293:251:468657001')

process.hltOutputMinimal.outputCommands = [
  'keep *_TriggerResults_*_HLTX',
  'keep *_hltSiPixelRecHitsFromLegacyPPOnAA_*_*',
  'keep *_hltSiPixelRecHitsPPOnAA_*_*',
  'keep *_hltSiPixelClustersPPOnAA_*_*',
  'keep *_hltSiPixelDigisPPOnAA_*_*',
  'keep *_hltSiPixelDigiErrorsPPOnAA_*_*',
  'keep *_hltPixelTracksPPOnAA_*_*',
  'keep *_hltPixelVerticesPPOnAA_*_*',
  'keep *_hlt*Muon*_*_*',
  'keep *_hlt*L2*_*_*',
  'keep *_hlt*L3*_*_*',
]

if hasattr(process, 'hltPixelConsumerGPUPPOnAA'):
    process.hltPixelConsumerGPUPPOnAA.eventProducts += [
        'hltSiPixelClustersPPOnAA',
        'hltPixelTracksPPOnAA',
        'hltPixelVerticesPPOnAA',
    ]

del process.MessageLogger
process.load('FWCore.MessageLogger.MessageLogger_cfi')

#process.options.accelerators = ['cpu']

#if process.hltPixelTracksPPOnAA.type_() == 'PixelTrackProducerFromSoAHIonPhase1':
#    process.hltPixelTracksPPOnAA.pixelRecHitLegacySrc = 'hltSiPixelRecHitsFromLegacyPPOnAA'
@EOF

  cmsRun "${1}".py &> "${1}".log
  mv output.root "${1}".root
}

run cmshlt3284_cpu_hlt1 /dev/CMSSW_14_0_0/HIon/V173
run cmshlt3284_cpu_hlt2 /users/soohwan/HLT_140X/Alpaka/HIonV173/V10
