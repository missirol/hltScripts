#!/bin/bash

hltGetConfiguration \
  /dev/CMSSW_13_0_0/GRun \
  --paths HLT_PFHT400_SixPFJet32_DoublePFBTagDeepJet_2p94_v* \
  --globaltag 126X_mcRun3_2023_forPU65_v3 \
  --mc \
  --unprescale \
  --output minimal \
  --max-events 400 \
  --input /store/mc/Run3Winter23Digi/TT_TuneCP5_13p6TeV_powheg-pythia8/GEN-SIM-RAW/126X_mcRun3_2023_forPU65_v1_ext1-v2/40002/cbcb2b23-174a-4e7f-a385-152d9c5c5b87.root \
  --eras Run3 --l1-emulator FullMC --l1 L1Menu_Collisions2023_v1_0_0_xml \
  > hlt1.py
cat <<@EOF >> hlt1.py
process.options.numberOfThreads = 1
@EOF
cmsRun hlt1.py &> hlt1.log

hltGetConfiguration \
  /users/missirol/test/dev/CMSSW_13_0_0/CMSHLT_2705/Test01/HLT \
  --setup /dev/CMSSW_13_0_0/GRun \
  --paths HLT_PFHT400_SixPFJet32_DoublePFBTagDeepJet_2p94_v* \
  --globaltag 126X_mcRun3_2023_forPU65_v3 \
  --mc \
  --unprescale \
  --output minimal \
  --max-events 400 \
  --input /store/mc/Run3Winter23Digi/TT_TuneCP5_13p6TeV_powheg-pythia8/GEN-SIM-RAW/126X_mcRun3_2023_forPU65_v1_ext1-v2/40002/cbcb2b23-174a-4e7f-a385-152d9c5c5b87.root \
  --eras Run3 --l1-emulator FullMC --l1 L1Menu_Collisions2023_v1_0_0_xml \
  > hlt2.py
cat <<@EOF >> hlt2.py
process.options.numberOfThreads = 1
@EOF
cmsRun hlt2.py &> hlt2.log
