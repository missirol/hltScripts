#!/bin/bash -ex

# CMSSW_14_0_4

hltGetConfiguration run:378940 \
  --globaltag 140X_dataRun3_HLT_v3 \
  --data \
  --no-prescale \
  --no-output \
  --max-events -1 \
  --input /store/group/tsg/FOG/debug/240405_run378940/files/run378940_ls0021_index000036_fu-c2b02-31-01_pid1363776.root \
  > hlt.py

cat <<@EOF >> hlt.py
process.options.wantSummary = True

process.options.numberOfThreads = 1
process.options.numberOfStreams = 0

process.options.accelerators = ["*"]

process.hltParticleFlowClusterHBHESoA.pfRecHitFractionAllocation = 250
@EOF

CUDA_LAUNCH_BLOCKING=1 \
cmsRun hlt.py &> hlt.log
