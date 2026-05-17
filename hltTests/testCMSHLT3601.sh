#!/bin/bash

hltIntegrationTests \
  /users/missirol/test/dev/CMSSW_15_0_0/CMSHLT_3561/Test01/HLT/V1 \
  -n 50 \
  --input /store/mc/Run3Winter25Digi/TT_TuneCP5_13p6TeV_powheg-pythia8/GEN-SIM-RAW/142X_mcRun3_2025_realistic_v7-v2/2810001/bac23860-7554-4578-9095-39f7dfc589fb.root \
  --mc \
  -x "--globaltag 142X_mcRun3_2025_realistic_v7" \
  -x "--eras Run3 --l1-emulator uGT --l1 L1Menu_Collisions2025_v1_2_0_xml" \
  -p DST_PFScouting_ZeroBiasVdM_v*,AlCa_LumiPixelsCounts_ZeroBiasGated_v*,HLT_ZeroBias_Gated_v* \
  -d output_hltIntegTests_CMSHLT3601 2>&1 | tee output_hltIntegTests_CMSHLT3601.txt
