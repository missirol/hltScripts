#!/bin/bash

hltGetConfiguration /frozen/2023/2e34/v1.2/HLT \
  --globaltag 130X_dataRun3_HLT_v2 \
  --data \
  --unprescale \
  --output all \
  --max-events 2000 \
  --paths DQM_*Reco*,*DQMGPUvsCPU* \
  --input /store/data/Run2023C/EphemeralHLTPhysics0/RAW/v1/000/368/822/00000/6e1268da-f96a-49f6-a5f0-89933142dd89.root \
  > hlt.py

cat <<EOF >> hlt.py
finalPathsToRemove = []
for fpath in process.finalpaths_():
  if 'DQMGPUvsCPU' not in fpath:
    finalPathsToRemove += [fpath]
for fpath in finalPathsToRemove:
  process.__delattr__(fpath)

process.hltOutputDQMGPUvsCPU.fileName = '___JOBNAME___.root'
EOF

cat <<EOF > modifyOutputDQMGPUvsCPU.txt
process.hltOutputDQMGPUvsCPU.outputCommands += [
  'keep SiPixelRawDataErroredmDetSetVector_hltSiPixelDigisFromSoA_*_*',
  'keep SiPixelRawDataErroredmDetSetVector_hltSiPixelDigisLegacy_*_*',
]
EOF

cat <<EOF > modifyDQMPixelConsumers1.txt
process.hltPixelConsumerCPU.eventProducts += ['hltSiPixelDigis@cpu']
process.hltPixelConsumerGPU.eventProducts += ['hltSiPixelDigis@cuda']
EOF

cat <<EOF > modifyDQMPixelConsumers2.txt
process.hltPixelConsumerCPU.eventProducts = ['hltSiPixelDigis@cpu']
process.hltPixelConsumerGPU.eventProducts = ['hltSiPixelDigis@cuda']
EOF

JOBNAME=hlt0
sed "s|___JOBNAME___|${JOBNAME}|" hlt.py > "${JOBNAME}".py
echo "${JOBNAME}" ... && cmsRun "${JOBNAME}".py &> "${JOBNAME}".log

JOBNAME=hlt1
sed "s|___JOBNAME___|${JOBNAME}|" hlt.py > "${JOBNAME}".py
cat modifyOutputDQMGPUvsCPU.txt >> "${JOBNAME}".py
echo "${JOBNAME}" ... && cmsRun "${JOBNAME}".py &> "${JOBNAME}".log

JOBNAME=hlt2
sed "s|___JOBNAME___|${JOBNAME}|" hlt.py > "${JOBNAME}".py
cat modifyOutputDQMGPUvsCPU.txt >> "${JOBNAME}".py
cat modifyDQMPixelConsumers1.txt >> "${JOBNAME}".py
echo "${JOBNAME}" ... && cmsRun "${JOBNAME}".py &> "${JOBNAME}".log

JOBNAME=hlt3
sed "s|___JOBNAME___|${JOBNAME}|" hlt.py > "${JOBNAME}".py
cat modifyOutputDQMGPUvsCPU.txt >> "${JOBNAME}".py
cat modifyDQMPixelConsumers2.txt >> "${JOBNAME}".py
echo "${JOBNAME}" ... && cmsRun "${JOBNAME}".py &> "${JOBNAME}".log

rm -f modifyOutputDQMGPUvsCPU.txt modifyDQMPixelConsumers.txt
