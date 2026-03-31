#!/bin/bash

# https://cmsdmops.docs.cern.ch/Users/Subscribe%20data/

datasets=(
#  /QCD_Bin-PT-15to7000_Par-PT-flat2022_TuneCP5_13p6TeV_pythia8/Run3Winter25Digi-NoPU_142X_mcRun3_2025_realistic_v9-v3/GEN-SIM-RAW
#  /QCD_Bin-PT-15to7000_Par-PT-flat2022_TuneCP5_13p6TeV_pythia8/Run3Winter25Digi-EpsilonPU_142X_mcRun3_2025_realistic_v9-v4/GEN-SIM-RAW
#  /QCD_Bin-PT-15to7000_Par-PT-flat2022_TuneCP5_13p6TeV_pythia8/Run3Winter25Digi-FlatPU0to120_142X_mcRun3_2025_realistic_v9-v4/GEN-SIM-RAW
#  /TT_TuneCP5_13p6TeV_powheg-pythia8/Run3Winter25Digi-142X_mcRun3_2025_realistic_v7-v2/GEN-SIM-RAW

  /store/data/Run2026B/L1Scouting/L1SCOUT/v1/000/402/144/00000/af07ed8c-d45e-41ad-81c7-8c32478c40be.root
  /store/data/Run2026B/L1ScoutingSelection/L1SCOUT/v1/000/402/144/00000/56a86b0d-c4a0-4ffc-84c5-158494ec8ecc.root
)

# rucio list-rules --account $RUCIO_ACCOUNT | grep ...

for dataset in "${datasets[@]}"; do

  rucio add-rule \
    cms:"${dataset}" \
    1 \
    'rse_type=DISK&cms_type=real\tier=3\tier=0' \
    --grouping 'ALL' \
    --lifetime 2592000 \
    --ask-approval \
    --activity "User AutoApprove" \
    --comment "L1-Scouting 2026 commissioning"

done
unset dataset
