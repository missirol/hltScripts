#!/bin/bash

hltGetConfiguration /dev/CMSSW_13_0_0/GRun \
   --paths HLT_PFHT400_SixPFJet32_DoublePFB*,HLT_PFHT370_v*\
   --globaltag 130X_dataRun3_HLT_v2 \
   --mc \
   --no-prescale \
   --output full \
   --max-events 1 \
   --input root://cms-xrd-global.cern.ch//store/data/Run2022G/EphemeralZeroBias1/RAW/v1/000/362/439/00000/c83fe13c-428e-4136-82f8-e1ff1f4453e1.root \
   --eras Run3 --l1-emulator FullMC --l1 L1Menu_Collisions2023_v1_0_0_xml \
   > hlt.py
cat <<@EOF >> hlt.py

del process.hltL1sHTT200er
del process.hltL1sHTT280to500erIorHTT250to340erQuadJet

del process.hltHT320Jet30

process.source.skipEvents = cms.untracked.uint32( 887 )

process.hltOutputFull.outputCommands = [
    'keep *',
    'drop *_hltSiPixelDigisLegacy_*_*',
    'drop *_hltSiPixelClustersLegacy_*_*',
    'drop *_hltSiPixelRecHitsFromLegacy_*_*',
    'drop *_hltEcalDigisLegacy_*_*',
    'drop *_hltEcalUncalibRecHitLegacy_*_*',
    'drop *_hltHbherecoLegacy_*_*',
]
@EOF
cmsRun hlt.py &> hlt.log
