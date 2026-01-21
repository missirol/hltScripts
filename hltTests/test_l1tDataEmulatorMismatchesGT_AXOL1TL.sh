#!/bin/bash

thisDir=$(dirname -- "${BASH_SOURCE[0]}")

cmsRun "${thisDir}"/test_l1tDataEmulatorMismatchesGT_cfg.py \
 -t 32 -n 20000 \
 -a L1_AXO_VLoose L1_AXO_Loose L1_AXO_Medium L1_AXO_Tight L1_AXO_VTight L1_AXO_VVTight L1_AXO_VVVTight \
 -i "/eos/cms/store/data/Run2025G/EphemeralHLTPhysics*/RAW/*/*/398/183/*/*.root" \
 -o tmp.root
