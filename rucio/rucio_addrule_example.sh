#!/bin/bash

# https://cmsdmops.docs.cern.ch/Users/Subscribe%20data/

datasets=(
#  /QCD_Bin-PT-15to7000_Par-PT-flat2022_TuneCP5_13p6TeV_pythia8/Run3Winter25Digi-NoPU_142X_mcRun3_2025_realistic_v9-v3/GEN-SIM-RAW
#  /QCD_Bin-PT-15to7000_Par-PT-flat2022_TuneCP5_13p6TeV_pythia8/Run3Winter25Digi-EpsilonPU_142X_mcRun3_2025_realistic_v9-v4/GEN-SIM-RAW
#  /QCD_Bin-PT-15to7000_Par-PT-flat2022_TuneCP5_13p6TeV_pythia8/Run3Winter25Digi-FlatPU0to120_142X_mcRun3_2025_realistic_v9-v4/GEN-SIM-RAW

/store/data/Run2026A/L1Scouting/L1SCOUT/v1/000/401/733/00000/81f5a1c5-a8d2-41bd-a9d8-54959c778d9f.root
/store/data/Run2026A/L1ScoutingSelection/L1SCOUT/v1/000/401/733/00000/52356b7e-e20e-4afb-bde6-6674e2b8b94f.root

)

# rucio list-rules --account $RUCIO_ACCOUNT | grep ...

for dataset in "${datasets[@]}"; do

  rucio add-rule \
    cms:"${dataset}" \
    1 \
    'rse_type=DISK&cms_type=real\tier=3\tier=0' \
    --grouping 'ALL' \
    --lifetime 1300000 \
    --ask-approval \
    --activity "User AutoApprove" \
    --comment "L1-Scouting 2026 commissioning"

done
unset dataset
