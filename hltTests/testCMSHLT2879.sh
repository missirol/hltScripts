#!/bin/bash

hltGetConfiguration \
  /users/jongho/cosmic_menu_for_CSCCluster \
  --data --globaltag 132X_dataRun3_HLT_v1 \
  --unprescale \
  --no-output \
  --max-events 200 \
  --input /store/data/Run2023D/HLTPhysics/RAW/v1/000/370/926/00000/d78101cc-55b0-47e7-bada-3d88a40a51b5.root \
  > hlt.py

cat <<EOF >> hlt.py
process.source.lumisToProcess = cms.untracked.VLuminosityBlockRange('370926:2031')

process.hltL1sMuShowerOneNominalEmu = process.hltL1sMuShowerOneNominal.clone(
    L1GlobalInputTag = "hltGtStage2ObjectMap"
)
process.HLT_CscCluster_CosmicEmu_v1 = cms.Path(
    process.HLTBeginSequence
  + process.hltL1sMuShowerOneNominalEmu
  + process.HLTMuonLocalRecoSequence
  + process.hltCSCrechitClusters
  + process.hltCscClusterCosmic
  + process.HLTEndSequence
)
process.schedule.extend([process.HLT_CscCluster_CosmicEmu_v1])

process.options.wantSummary = True
EOF

cmsRun hlt.py &> hlt.log
