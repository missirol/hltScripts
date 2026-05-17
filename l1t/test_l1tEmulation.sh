#!/bin/bash

# scram p CMSSW CMSSW_12_3_0_pre3
# cd CMSSW_12_3_0_pre3
# eval `scram runtime -sh`
# git cms-init --ssh
# git cms-addpkg L1Trigger/L1TGlobal
# mkdir -p L1Trigger/L1TGlobal/data/Luminosity/startup
# wget https://raw.githubusercontent.com/cms-l1-dpg/L1MenuRun3/master/development/L1Menu_Collisions2022_v0_1_2/L1Menu_Collisions2022_v0_1_2.xml \
#  -O L1Trigger/L1TGlobal/data/Luminosity/startup/L1Menu_Collisions2022_v0_1_2.xml
# scram b -j 4

#inputEdmFile=/store/relval/CMSSW_12_0_1/RelValTTbar_14TeV/GEN-SIM-DIGI-RAW/120X_mcRun3_2021_realistic_v7-v2/10000/b67e121b-b29f-4eb0-8628-b3aa1cb76720.root
inputEdmFile=/store/relval/CMSSW_12_3_0_pre2/RelValTTbar_14TeV/GEN-SIM-DIGI-RAW/PU_122X_mcRun3_2021_realistic_v5-v1/2580000/263b9f70-a3d2-4f36-9eef-3ba5e97f8ec1.root

hltGetConfiguration /dev/CMSSW_12_3_0/GRun --dbproxy \
 --mc --full --unprescale --globaltag auto:phase1_2021_realistic --process MYHLT --output minimal \
 --l1Xml L1Menu_Collisions2022_v0_1_2.xml --l1-emulator uGT \
 --max-events 1 \
 --input "${inputEdmFile}" \
 > hlt_cfg.py

edmConfigDump hlt_cfg.py > hlt_cfgDump.py
edmConfigDump --prune hlt_cfg.py > hlt_cfgDumpPruned.py

cmsRun hlt_cfg.py &> hlt_cfg.log
