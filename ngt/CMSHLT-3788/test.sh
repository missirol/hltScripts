#!/bin/bash -ex

hltLabel=testAddTriggerEvents
hltLabel1="${hltLabel}"_hlt1
hltLabel2="${hltLabel}"_hlt2

INPUTFILES="root://eoscms.cern.ch//store/data/Run2025G/EphemeralHLTPhysics0/RAW/v1/000/398/183/00000/002bbd0c-b9ed-4758-b7a6-e2e13149ca34.root"
#MENU=/users/musich/tests/dev/CMSSW_16_0_0/CMSHLT-3712/HLT/V1 
MENU=/dev/CMSSW_16_0_0/GRun/V31

hltGetConfiguration $MENU \
   --globaltag 160X_dataRun3_HLT_v1 \
   --data \
   --unprescale \
   --output all \
   --max-events -1 \
   --eras Run3_2026 --l1-emulator uGT --l1 L1Menu_Collisions2026_v1_0_0_xml \
   --input $INPUTFILES \
   > ${hltLabel1}.py

# hltLabel1
cat <<@EOF >> ${hltLabel1}.py
del process.MessageLogger
process.load('FWCore.MessageLogger.MessageLogger_cfi')

del process.dqmOutput
streamPaths = [foo for foo in process.endpaths_() if foo.endswith('Output')]
streamPaths.remove('DQMTestDataScoutingOutput')
for foo in streamPaths:
	   process.__delattr__(foo)

# drop previous HLT output	   
process.hltOutputDQMTestDataScouting.outputCommands += ["drop *_*_*_HLT"]
process.hltOutputDQMTestDataScouting.fileName = "${hltLabel1}_DQMTestDataScouting.root"
@EOF

# process.hltOutputMinimal.outputCommands = [
#     'keep *_hltFEDSelectorL1_*_*',
#     'keep *_hltOnlineMetaDataDigis_*_*',
#     'keep *_hltScoutingEgammaPacker_*_*',
#     'keep *_hltScoutingMuonPackerNoVtx_*_*',
#     'keep *_hltScoutingMuonPackerVtx_*_*',
#     'keep *_hltScoutingPFPacker_*_*',
#     'keep *_hltScoutingPrimaryVertexPacker_*_*',
#     'keep *_hltScoutingRecHitPacker_*_*',
#     'keep *_hltScoutingTrackPacker_*_*',
#     'keep CTPPSDiamondDigiedmDetSetVector_hltCTPPSDiamondRawToDigi_*_*',
#     'keep CTPPSPixelDigiedmDetSetVector_hltCTPPSPixelDigis_*_*',
#     'keep edmTriggerResults_*_*_*',
# ]

cp "${hltLabel1}".py "${hltLabel2}".py

cmsRun "${hltLabel1}".py >& "${hltLabel1}".log

# hltLabel2
cat <<@EOF >> "${hltLabel2}".py
process.hltOutputDQMTestDataScouting.fileName = "${hltLabel2}_DQMTestDataScouting.root"
process.hltOutputDQMTestDataScouting.outputCommands += ['keep triggerTriggerEvent_*_*_HLTX']
@EOF

cmsRun "${hltLabel2}".py >& "${hltLabel2}".log
