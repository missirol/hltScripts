#!/bin/bash

[ $# -ge 1 ] || exit 1

hltLabel=hlt
outDir="${1}"

[ ! -d "${outDir}" ] || exit 1

mkdir -p "${outDir}"
cd "${outDir}"

hltGetConfiguration /dev/CMSSW_14_0_0/GRun/V173 \
  --globaltag 140X_dataRun3_HLT_v3 \
  --data \
  --no-prescale \
  --output minimal \
  --max-events -1 \
  --input root://eoscms.cern.ch//eos/cms/store/group/tsg/STEAM/validations/GPUVsCPU/240814/raw_pickevents.root \
  --eras Run3_2024 --l1-emulator uGT --l1 L1Menu_Collisions2024_v1_3_0_xml \
  > "${hltLabel}"1.py

cat <<@EOF >> "${hltLabel}"1.py
process.options.numberOfThreads = 1
process.options.numberOfStreams = 0
process.options.wantSummary = True

for foo in ['HLTAnalyzerEndpath', 'dqmOutput', 'MessageLogger']:
    if hasattr(process, foo):
        process.__delattr__(foo)

process.load('FWCore.MessageLogger.MessageLogger_cfi')

process.hltOutputMinimal.outputCommands = [
  'drop *',
  'keep *_TriggerResults_*_*',
  'keep *_hltPixelTracks_*_*',
  'keep *_hltPixelVertices_*_*',
]
@EOF

CUDA_LAUNCH_BLOCKING=1 \
cmsRun "${hltLabel}"1.py &> "${hltLabel}"1.log
mv output.root "${hltLabel}"1.root

cp "${hltLabel}"1.py "${hltLabel}"2.py
cat <<@EOF >> "${hltLabel}"2.py

#process.options.accelerators = ['cpu']

#process.hltEcalDigisSoA.alpaka.backend = 'serial_sync'
#process.hltEcalUncalibRecHitSoA.alpaka.backend = 'serial_sync'
#process.hltHbheRecoSoA.alpaka.backend = 'serial_sync'
#process.hltParticleFlowRecHitHBHESoA.alpaka.backend = 'serial_sync'
#process.hltParticleFlowClusterHBHESoA.alpaka.backend = 'serial_sync'
#process.hltOnlineBeamSpotDevice.alpaka.backend = 'serial_sync'
#process.hltSiPixelClustersSoA.alpaka.backend = 'serial_sync'
#process.hltSiPixelRecHitsSoA.alpaka.backend = 'serial_sync'
process.hltPixelTracksSoA.alpaka.backend = 'serial_sync'
process.hltPixelVerticesSoA.alpaka.backend = 'serial_sync'
@EOF

CUDA_LAUNCH_BLOCKING=1 \
cmsRun "${hltLabel}"2.py &> "${hltLabel}"2.log
mv output.root "${hltLabel}"2.root
