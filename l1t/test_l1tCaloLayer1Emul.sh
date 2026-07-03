#!/bin/bash -ex

# cmsrel CMSSW_17_0_0_pre2
# cd CMSSW_17_0_0_pre2/src
# cmsenv
#
# git cms-addpkg L1Trigger/L1TCalorimeter
#
# wget https://raw.githubusercontent.com/cms-sw/cmssw/819219877de0b0c4090f668d6463323b6fcf8af6/L1Trigger/L1TCalorimeter/python/caloParamsHI_2026_v0_2_cfi.py \
#  -O L1Trigger/L1TCalorimeter/python/caloParamsHI_2026_v0_2_cfi.py
#
# wget https://raw.githubusercontent.com/missirol/cmssw/a39e1221cfc6f6892bed4f7592405dc2ff2a29bb/L1Trigger/L1TCalorimeter/python/caloParamsHI_2026_v0_X_cfi.py \
#  -O L1Trigger/L1TCalorimeter/python/caloParamsHI_2026_v0_X_cfi.py
#
# scram b

thisDir=$(dirname -- "${BASH_SOURCE[0]}")

run_test () {
  [ $# -ge 1 ] || return

  cmsRun "${thisDir}"/test_l1tCaloLayer1Emul_DQM_cfg.py \
    -i /store/hidata/HIRun2026A/HIHLTPhysics/RAW/v1/000/404/576/00000/df5d2a95-167c-4258-a097-e8804e536053.root \
    -l rawDataRepacker \
    -g 161X_dataRun3_Prompt_v1 \
    -n -1 \
    -o tmp_DQMIO.root \
    "${@:2}"

  cmsRun "${thisDir}"/test_l1tCaloLayer1Emul_harvesting_cfg.py \
    -i file:tmp_DQMIO.root -o "/XXX/YYY/ZZZ"

  rm -rf tmp_DQMIO.root __pycache__

  mv DQM*__XXX__YYY__ZZZ.root "${1}"
}

run_test dqmL1TCaloLayer1_HIHLTPhysics_GlobalTag.root
run_test dqmL1TCaloLayer1_HIHLTPhysics_GlobalTag_noCaloMask.root --ignoreCaloMask
run_test dqmL1TCaloLayer1_HIHLTPhysics_caloParamsHI_2026_v0_2_noCaloMask.root --ignoreCaloMask -c caloParamsHI_2026_v0_2_cfi
run_test dqmL1TCaloLayer1_HIHLTPhysics_caloParamsHI_2026_v0_X_noCaloMask.root --ignoreCaloMask -c caloParamsHI_2026_v0_X_cfi
