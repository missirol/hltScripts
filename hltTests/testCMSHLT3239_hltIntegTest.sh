#!/bin/bash

hltIntegrationTests \
  /users/missirol/test/dev/CMSSW_14_0_0/CMSHLT_3239/Test06/GRun/V2 \
  -n 100 \
  --input /store/relval/CMSSW_14_0_1/RelValTTbar_14TeV/GEN-SIM-DIGI-RAW/140X_mcRun3_2024_realistic_v4_PU_AlpakaVal_AlpakaDeviceVSHost-v8/2810000/4632f839-54fa-463f-ae1d-6067e3634bb6.root \
  --mc \
  -x "--globaltag auto:phase1_2024_realistic" \
  -x "--eras Run3 --l1-emulator uGT --l1 L1Menu_Collisions2024_v1_2_0-d1_xml" \
  --paths AlCa_PFJet*,HLT_DoubleL2Mu23NoVtx_2Cha_CosmicSeed_v* \
  -d output_hltIntegTests_CMSHLT3239 2>&1 | tee output_hltIntegTests_CMSHLT3239.txt
