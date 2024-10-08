#!/bin/bash

run(){

  https_proxy=http://cmsproxy.cms:3128/ \
  hltGetConfiguration "${2}" \
    --globaltag 140X_dataRun3_HLT_v3 \
    --data \
    --unprescale \
    --output minimal \
    --max-events 1000 \
    --eras Run3_2024 --l1-emulator uGT --l1 L1Menu_CollisionsHeavyIons2023_v1_1_5_xml \
    --paths HLT_HIL3DoubleMu0_M2to4p5_Open_v* \
    --input root://eoscms.cern.ch//eos/cms/store/user/cmsbuild/store/data/Run2023D/EphemeralHLTPhysics0/RAW/v1/000/370/293/00000/2ef73d2a-1fb7-4dac-9961-149525f9e887.root \
    > "${1}".py

  cat <<@EOF >> "${1}".py

process.options.numberOfThreads = 1
process.options.numberOfStreams = 0

process.hltOutputMinimal.outputCommands = [
  'keep *_hltOnlineBeamSpot*_*_*',
  'keep *_hltSiPixelClustersPPOnAA_*_*',
  'keep *_hltPixelTracksPPOnAA_*_*',
  'keep *_hltPixelVerticesPPOnAA_*_*',
  'keep *_hlt*Muon*_*_*',
  'keep *_hlt*L2*_*_*',
  'keep *_hlt*L3*_*_*',
  'keep *_hltPixelTracksInRegionL1PPOnAA_*_*',
  'keep *_hltIterL3FromL1MuonPixelTracksTrackingRegionsPPOnAA_*_*',
  'keep *_TriggerResults_*_*'
]

if hasattr(process, 'hltPixelConsumerGPUPPOnAA'):
   process.hltPixelConsumerGPUPPOnAA.eventProducts += [
       'hltSiPixelClustersPPOnAA',
       'hltPixelTracksPPOnAA',
       'hltPixelVerticesPPOnAA',
       'hltPixelTracksInRegionL1PPOnAA',
       'hltIterL3FromL1MuonPixelTracksTrackingRegionsPPOnAA'
   ]

del process.MessageLogger
process.load('FWCore.MessageLogger.MessageLogger_cfi')
@EOF

  cmsRun "${1}".py &> "${1}".log
  mv output.root "${1}".root
}

run hlt1 /dev/CMSSW_14_0_0/HIon/V173
run hlt2 /users/soohwan/HLT_140X/Alpaka/HIonV173/V10

cp hlt2.py hlt3.py
cat <<@EOF >> hlt3.py

process.hltPixelTracksPPOnAASoA = cms.EDProducer("CAHitNtupletAlpakaHIonPhase1@alpaka",
    **process.hltPixelTracksPPOnAASoA.parameters_()
)
process.hltPixelVerticesPPOnAASoA = cms.EDProducer("PixelVertexProducerAlpakaHIonPhase1@alpaka",
    **process.hltPixelVerticesPPOnAASoA.parameters_()
)
@EOF
cmsRun hlt3.py &> hlt3.log
mv output.root hlt3.root
