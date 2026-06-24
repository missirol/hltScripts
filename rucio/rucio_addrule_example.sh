#!/bin/bash

# https://cmsdmops.docs.cern.ch/Users/Subscribe%20data/

datasets=(
#  /QCD_Bin-PT-15to7000_Par-PT-flat2022_TuneCP5_13p6TeV_pythia8/Run3Winter25Digi-NoPU_142X_mcRun3_2025_realistic_v9-v3/GEN-SIM-RAW
#  /QCD_Bin-PT-15to7000_Par-PT-flat2022_TuneCP5_13p6TeV_pythia8/Run3Winter25Digi-EpsilonPU_142X_mcRun3_2025_realistic_v9-v4/GEN-SIM-RAW
#  /QCD_Bin-PT-15to7000_Par-PT-flat2022_TuneCP5_13p6TeV_pythia8/Run3Winter25Digi-FlatPU0to120_142X_mcRun3_2025_realistic_v9-v4/GEN-SIM-RAW
#  /TT_TuneCP5_13p6TeV_powheg-pythia8/Run3Winter25Digi-142X_mcRun3_2025_realistic_v7-v2/GEN-SIM-RAW

/HLTPhysics/Run2026A-v1/RAW
/HLTPhysics/Run2026B-v1/RAW
/HLTPhysics/Run2026C-v1/RAW
/HLTPhysics/Run2026D-v1/RAW

/L1Scouting/Run2026A-v1/L1SCOUT
/L1Scouting/Run2026B-v1/L1SCOUT
/L1Scouting/Run2026C-v1/L1SCOUT
/L1Scouting/Run2026D-v1/L1SCOUT
)

# rucio list-rules --account $RUCIO_ACCOUNT | grep ...

for dataset in "${datasets[@]}"; do

  rucio add-rule \
    cms:"${dataset}" \
    1 \
    'rse_type=DISK&cms_type=real\tier=3\tier=0' \
    --grouping 'ALL' \
    --lifetime 13000000 \
    --ask-approval \
    --activity "User AutoApprove" \
    --comment "L1-Scouting 2026 commissioning"

done
unset dataset
