#!/bin/bash

hltLabel="${1}"

hltGetConfiguration run:404359 \
 --eras Run3_2026 \
 --no-output \
 --globaltag 161X_dataRun3_HLT_v1 --data \
 --input file:/eos/cms/tier0/store/hidata/HIRun2026A/HIHLTPhysics/RAW/v1/000/404/359/00000/a1868590-8ccc-4ea4-ac80-25d053bce2ba.root \
 --max-events 500 \
 --customise HLTrigger/Configuration/CustomConfigs.customiseHLTforHIonRepackedRAW \
 > "${hltLabel}".py

cat <<@EOF >> "${hltLabel}".py

process.options.numberOfThreads = 1
process.options.numberOfStreams = 0
process.options.wantSummary = False

process.SimpleMemoryCheck = cms.Service("SimpleMemoryCheck",
    ignoreTotal = cms.untracked.int32(1),
    oncePerEventMode = cms.untracked.bool32(True)
)
@EOF

valgrind --tool=massif --pages-as-heap=yes \
cmsRun "${hltLabel}".py &> "${hltLabel}".log

grep ' RSS ' "${hltLabel}".log > "${hltLabel}"_rss.log

valgrind --tool=memcheck $(cmsvgsupp) \
 --suppressions="${ROOTSYS}"/etc/valgrind-root.supp \
 --suppressions="${ROOTSYS}"/etc/valgrind-root-python.supp \
 --num-callers=20 --track-origins=yes \
 cmsRun "${hltLabel}".py &> "${hltLabel}"_memcheck.log
