#!/bin/bash

thisDir=$(dirname -- "${BASH_SOURCE[0]}")

cmsRun "${thisDir}"/test_l1tDataEmulatorMismatchesGT_cfg.py \
  --no-out -p TEST2 -n -1 -e 1 \
  -i /eos/user/m/missirol/test_l1tDataEmulatorMismatchesGT_Tau3Mu.root \
  -a L1_TripleMu_3SQ_2p5SQ_0_Mass_Max12
