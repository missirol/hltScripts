#!/bin/bash

runHLT(){
  rm -rf $1
  mkdir -p $1
  cd $1
  hltGetConfiguration $2 \
    --globaltag 130X_dataRun3_HLT_v2 \
    --mc \
    --unprescale \
    --output all \
    --max-events 5000 \
    --paths *RPC* \
    --input /store/data/Run2023D/EphemeralHLTPhysics0/RAW/v1/000/370/293/00000/2ef73d2a-1fb7-4dac-9961-149525f9e887.root \
    > hlt.py
  cat <<EOF >> hlt.py
# remove paths containing OutputModules
streamPaths = [pathName for pathName in process.finalpaths_()]
for foo in streamPaths:
    if 'RPCMON' not in foo:
        process.__delattr__(foo)
EOF
  cmsRun hlt.py &> hlt.log
  cd -
}

runHLT out_GRunV146 /dev/CMSSW_13_0_0/GRun/V146
runHLT out_GRunV147 /dev/CMSSW_13_0_0/GRun/V147
