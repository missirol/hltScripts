#!/bin/bash -ex

# cmsrel CMSSW_13_3_0_pre1
# cd CMSSW_13_3_0_pre1/src
# cmsenv
# git checkout -b test_cmssw42441
# git cms-merge-topic cms-sw:42441
# git cms-remote add missirol
# git cms-addpkg HLTrigger/HLTfilters
# git cp b67f107964f
# scram b -j 16

# run 366497, LS 196
INPUTFILE=root://eoscms.cern.ch//store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/FOG/error_stream/run366497/run366497_ls0196_index000095_fu-c2b01-26-01_pid1955211.root

RUNNUM=366497

run_test() {
  rm -rf run"${RUNNUM}"*
  convertToRaw -f 100 -l 100 -r "${RUNNUM}":196 -o . -- "${INPUTFILE}"
  edmConfigDump "${tmpfile}" > "${1}".py
  cmsRun "${1}".py &> "${1}".log || true
}

tmpfile=$(mktemp)
hltConfigFromDB --runNumber "${RUNNUM}" > "${tmpfile}"
cat <<@EOF >> "${tmpfile}"

process.load('run${RUNNUM}_cff')

# customisations to adapt 13_0_X HLT menus to CMSSW_13_3_0_pre1
from HLTrigger.Configuration.customizeHLTforCMSSW import customizeHLTforCMSSW
process = customizeHLTforCMSSW(process)

# remove prescales, and set GlobalTag
del process.PrescaleService
process.GlobalTag.globaltag = '130X_dataRun3_HLT_v2'

# show statistics on decisions of modules and Paths
process.options.wantSummary = True

# number of threads/streams used online by HLT
process.options.numberOfThreads = 32
process.options.numberOfStreams = 24
@EOF

# hlt5: send events with at least one Path in error state to a separate output file, using the syntax "exception@*"
jobLabel="hlt5"
cat <<@EOF >> "${tmpfile}"

process.options.TryToContinue = cms.untracked.vstring( 'InvalidGlobalAlgBlkBxCollection' )

# "StreamPath": FinalPath with OutputModule selecting on DatasetPath
process.hltOutputHLTError = cms.OutputModule("GlobalEvFOutputModule",
    SelectEvents = cms.untracked.PSet(
        SelectEvents = cms.vstring(
            'exception@*'
        )
    ),
    compression_algorithm = cms.untracked.string('ZSTD'),
    compression_level = cms.untracked.int32(3),
    lumiSection_interval = cms.untracked.int32(0),
    outputCommands = cms.untracked.vstring(
        'drop *',
        'keep FEDRawDataCollection_rawDataCollector_*_*',
        'keep FEDRawDataCollection_source_*_*',
        'keep GlobalObjectMapRecord_hltGtStage2ObjectMap_*_*',
        'keep edmTriggerResults_*_*_*',
        'keep triggerTriggerEvent_*_*_*'
    ),
    psetMap = cms.untracked.InputTag("hltPSetMap"),
    use_compression = cms.untracked.bool(True)
)

process.HLTErrorOutput = cms.FinalPath( process.hltOutputHLTError )

# update cms.Schedule adding (Final)Path with new OutputModule
process.schedule.append( process.HLTErrorOutput )
@EOF
run_test "${jobLabel}"
