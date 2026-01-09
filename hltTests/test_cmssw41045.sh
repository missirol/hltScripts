#!/bin/bash

testTag=testHLT_tmp

hltGetConfiguration /dev/CMSSW_13_0_0/HLT/V79 \
   --globaltag 126X_mcRun3_2023_forPU65_v3 \
   --mc \
   --no-prescale \
   --no-output \
   --max-events -1 \
   --input /store/mc/Run3Winter23Digi/TT_TuneCP5_13p6TeV_powheg-pythia8/GEN-SIM-RAW/126X_mcRun3_2023_forPU65_v1_ext1-v2/40002/cbcb2b23-174a-4e7f-a385-152d9c5c5b87.root \
   --eras Run3 --l1-emulator FullMC --l1 L1Menu_Collisions2023_v1_0_0_xml \
   > "${testTag}".py

cat <<@EOF >> "${testTag}".py
del process.hltMuonTriggerResultsFilter

# hltGetConfiguration /dev/CMSSW_13_0_0/GRun/V79 > grun.py
from grun import process as grun
grunPaths = [pathName for pathName in grun.paths_() if not pathName.startswith('Dataset_')]

extraPaths = [
  'HLT_Mu8_TrkIsoVVL_Ele23_CaloIdL_TrackIdL_IsoVL_DZ_CaloDiJet30_CaloBtagDeepCSV_1p5_v',
  'HLT_Ele15_IsoVVVL_PFHT450_CaloBTagDeepCSV_4p5_v',
  'HLT_Mu15_IsoVVVL_PFHT450_CaloBTagDeepCSV_4p5_v',
  'HLT_DoublePFJets116MaxDeta1p6_DoublePFBTagDeepCSV_p71_v',
  'HLT_DoublePFJets128MaxDeta1p6_DoublePFBTagDeepCSV_p71_v',
  'HLT_Mu12_DoublePFJets40MaxDeta1p6_DoublePFBTagDeepCSV_p71_v',
  'HLT_Mu12_DoublePFJets54MaxDeta1p6_DoublePFBTagDeepCSV_p71_v',
  'HLT_Mu12_DoublePFJets40_PFBTagDeepCSV_p71_v',
  'HLT_Mu12_DoublePFJets100_PFBTagDeepCSV_p71_v',
  'HLT_Mu12_DoublePFJets200_PFBTagDeepCSV_p71_v',
  'HLT_Mu12_DoublePFJets350_PFBTagDeepCSV_p71_v',
  'HLT_DoublePFJets40_PFBTagDeepCSV_p71_v',
  'HLT_DoublePFJets100_PFBTagDeepCSV_p71_v',
  'HLT_DoublePFJets200_PFBTagDeepCSV_p71_v',
  'HLT_DoublePFJets350_PFBTagDeepCSV_p71_v',
  'HLT_PFHT450_SixPFJet36_PFBTagDeepCSV_1p59_v',
  'HLT_Mu8_TrkIsoVVL_Ele23_CaloIdL_TrackIdL_IsoVL_DZ_PFDiJet30_PFBtagDeepCSV_1p5_v',
  'HLT_PFHT400_SixPFJet32_DoublePFBTagDeepCSV_2p94_v',
  'HLT_PFHT400_FivePFJet_100_100_60_30_30_DoublePFBTagDeepCSV_4p5_v',
  'HLT_PFHT400_FivePFJet_120_120_60_30_30_DoublePFBTagDeepCSV_4p5_v',
  'HLT_PFHT330PT30_QuadPFJet_75_60_45_40_TriplePFBTagDeepCSV_4p5_v',
  'HLT_Mu6HT240_DisplacedDijet30_Inclusive0PtrkShortSig5_v',
]

rmPaths = []
for pathName in process.paths_():
  keep = False
  for keepPath in grunPaths+extraPaths:
    if pathName.startswith(keepPath):
      keep = True
      break
  if not keep:
    rmPaths += [pathName]

for pathName in rmPaths:
  process.__delattr__(pathName)
@EOF

cmsRun "${testTag}".py &> "${testTag}".log
