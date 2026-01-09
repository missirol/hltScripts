#!/bin/bash

hltGetConfiguration \
  /users/missirol/test/dev/CMSSW_13_0_0/CMSHLT_2635/Test02/HLT/V1 \
  --setup /dev/CMSSW_13_0_0/GRun \
  --input \
/store/mc/Run3Winter23Digi/BuToKee_SoftQCDnonD_TuneCP5_13p6TeV_pythia8-evtgen/GEN-SIM-RAW/126X_mcRun3_2023_forPU65_v1-v2/30000/59978489-abf1-4ab3-b249-147e6d236e11.root,\
/store/mc/Run3Winter23Digi/BuToKee_SoftQCDnonD_TuneCP5_13p6TeV_pythia8-evtgen/GEN-SIM-RAW/126X_mcRun3_2023_forPU65_v1-v2/30000/661c24ca-c1e3-4d86-822b-65eceb251149.root,\
/store/mc/Run3Winter23Digi/BuToKee_SoftQCDnonD_TuneCP5_13p6TeV_pythia8-evtgen/GEN-SIM-RAW/126X_mcRun3_2023_forPU65_v1-v2/30000/fb5aa514-b5e8-43d9-8804-5b5483db02e9.root,\
/store/mc/Run3Winter23Digi/BuToKee_SoftQCDnonD_TuneCP5_13p6TeV_pythia8-evtgen/GEN-SIM-RAW/126X_mcRun3_2023_forPU65_v1-v2/30000/18bbcff8-73fb-4210-b580-0821aebefbe7.root,\
/store/mc/Run3Winter23Digi/BuToKee_SoftQCDnonD_TuneCP5_13p6TeV_pythia8-evtgen/GEN-SIM-RAW/126X_mcRun3_2023_forPU65_v1-v2/30000/080f63b5-4f6e-46fd-8d44-e5b81240c57a.root,\
/store/mc/Run3Winter23Digi/BuToKee_SoftQCDnonD_TuneCP5_13p6TeV_pythia8-evtgen/GEN-SIM-RAW/126X_mcRun3_2023_forPU65_v1-v2/30000/5dff7d74-7b6c-4e79-9ee4-7b8d85058ebf.root,\
/store/mc/Run3Winter23Digi/BuToKee_SoftQCDnonD_TuneCP5_13p6TeV_pythia8-evtgen/GEN-SIM-RAW/126X_mcRun3_2023_forPU65_v1-v2/30000/c6b67e72-2668-4d03-8a44-9a330a19066c.root,\
/store/mc/Run3Winter23Digi/BuToKee_SoftQCDnonD_TuneCP5_13p6TeV_pythia8-evtgen/GEN-SIM-RAW/126X_mcRun3_2023_forPU65_v1-v2/30000/0e7122f5-05e5-4184-abd3-37fe37ef0bbb.root,\
/store/mc/Run3Winter23Digi/BuToKee_SoftQCDnonD_TuneCP5_13p6TeV_pythia8-evtgen/GEN-SIM-RAW/126X_mcRun3_2023_forPU65_v1-v2/30000/936c982e-cede-4236-98d6-a637c66825c6.root \
  --mc \
  --max-events 5000 \
  --globaltag 126X_mcRun3_2023_forPU65_v1 \
  --no-prescale \
  --output minimal \
  --eras Run3 \
  --l1-emulator FullMC \
  --l1 L1Menu_Collisions2022_v1_4_0-d1_xml \
  > hlt_testEG_MC.py

cmsRun hlt_testEG_MC.py &> hlt_testEG_MC.log
