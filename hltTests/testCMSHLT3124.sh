#!/bin/bash -ex

# CMSSW_14_0_0_pre3{,_MULTIARCHS}

hltGetConfiguration /dev/CMSSW_14_0_0/GRun/V73 \
  --globaltag 140X_dataRun3_HLT_v3 \
  --data \
  --unprescale \
  --output minimal \
  --max-events -1 \
  --paths HLT_Ele30_WPTight_Gsf_v* \
  --input \
/store/group/tsg/STEAM/validations/CMSHLT-3124/check_01/files/pickEvents_Run2023D_EphemeralHLTPhysics0.root,\
/store/group/tsg/STEAM/validations/CMSHLT-3124/check_01/files/pickEvents_Run2023D_EphemeralHLTPhysics1.root,\
/store/group/tsg/STEAM/validations/CMSHLT-3124/check_01/files/pickEvents_Run2023D_EphemeralHLTPhysics2.root,\
/store/group/tsg/STEAM/validations/CMSHLT-3124/check_01/files/pickEvents_Run2023D_EphemeralHLTPhysics3.root,\
/store/group/tsg/STEAM/validations/CMSHLT-3124/check_01/files/pickEvents_Run2023D_EphemeralHLTPhysics4.root,\
/store/group/tsg/STEAM/validations/CMSHLT-3124/check_01/files/pickEvents_Run2023D_EphemeralHLTPhysics5.root,\
/store/group/tsg/STEAM/validations/CMSHLT-3124/check_01/files/pickEvents_Run2023D_EphemeralHLTPhysics6.root,\
/store/group/tsg/STEAM/validations/CMSHLT-3124/check_01/files/pickEvents_Run2023D_EphemeralHLTPhysics7.root \
  > hlt.py

cat <<@EOF >> hlt.py
process.hltParticleFlowClusterHBHE.pfClusterParams = cms.ESInputTag('')

process.options.numberOfThreads = 1
process.options.numberOfStreams = 0

process.hltOutputMinimal.outputCommands += [
    'keep *_hlt*Track*_*_*',
    'keep *_hlt*Vert*_*_*',
    'keep *_hltParticleFlowSuperClusterECAL*_*_*',
    'keep *_hltEgamma*_*_*',
    'drop *_hlt*GPU*_*_*',
]
@EOF

for nnn in {0..2}; do
  cmsRun hlt.py &> hlt"${nnn}".log
  mv output.root hlt"${nnn}".root
  grep -a TrigReport hlt"${nnn}".log | head -118 > hlt"${nnn}".txt
done; unset nnn
