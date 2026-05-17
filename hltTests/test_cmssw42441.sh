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

# hlt1: reproduce online crash seen in run 366497 (LS 196)
jobLabel="hlt1"
run_test "${jobLabel}"

# hlt2: hlt1 + "try to continue" upon exceptions of type 'InvalidGlobalAlgBlkBxCollection'
jobLabel="hlt2"
cat <<@EOF >> "${tmpfile}"

process.options.TryToContinue = cms.untracked.vstring( 'InvalidGlobalAlgBlkBxCollection' )
@EOF
run_test "${jobLabel}"

# hlt3: hlt2 + send events to a separate PrimaryDataset and stream
jobLabel="hlt3"
cat <<@EOF >> "${tmpfile}"

# New Path to select events in which at least one other Path went in Error state
process.HLTBeginSequenceAny = cms.Sequence( process.hltGtStage2Digis )

process.hltPrePathStatusError = cms.EDFilter( "HLTPrescaler",
    offset = cms.uint32( 0 ),
    L1GtReadoutRecordTag = cms.InputTag( "hltGtStage2Digis" )
)

process.hltPathStatusErrorFilter = cms.EDFilter( "HLTPathStatusErrorFilter",
  ignoreInvalidPathNames = cms.bool(False),
  # consider all Paths in the configuration ..
  pathNames = cms.vstring( '*' ),
  # .. except for the Path holding this module, as well as DatasetPaths
  pathNamesToSkip = cms.vstring( 'HLT_PathStatusError_v*', 'Dataset_*' ),
)

process.HLT_PathStatusError_v1 = cms.Path(
    process.HLTBeginSequenceAny
  + process.hltPrePathStatusError
  + process.hltPathStatusErrorFilter
  + process.HLTEndSequence
)

# "DatasetPath": Path using TriggerResultsFilter to select on other Paths
process.hltPreDatasetHLTError = cms.EDFilter( "HLTPrescaler",
    offset = cms.uint32( 0 ),
    L1GtReadoutRecordTag = cms.InputTag( "hltGtStage2Digis" )
)

process.hltDatasetHLTError = cms.EDFilter( "TriggerResultsFilter",
    usePathStatus = cms.bool( True ),
    hltResults = cms.InputTag( "" ),
    l1tResults = cms.InputTag( "" ),
    l1tIgnoreMaskAndPrescale = cms.bool( False ),
    throw = cms.bool( True ),
    triggerConditions = cms.vstring( 'HLT_PathStatusError_v1' )
)

process.Dataset_HLTError = cms.Path(
    process.HLTDatasetPathBeginSequence
  + process.hltDatasetHLTError
  + process.hltPreDatasetHLTError
)

# "StreamPath": FinalPath with OutputModule selecting on DatasetPath
process.hltOutputHLTError = cms.OutputModule("GlobalEvFOutputModule",
    SelectEvents = cms.untracked.PSet(
        SelectEvents = cms.vstring(
            'Dataset_HLTError'
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

# update cms.Schedule adding new Path, DatasetPath, and StreamPath
process.schedule.extend([
    process.HLT_PathStatusError_v1,
    process.Dataset_HLTError,
    process.HLTErrorOutput
])

# update the global PSets "datasets" and "streams"
# (just to mimic the db->python converter of ConfDB)
process.datasets.HLTError = cms.vstring( 'HLT_PathStatusError_v1' )
process.streams.HLTError = cms.vstring( 'HLTError' )

# prevent the Paths HLT_PathStatusError_v1 and Dataset_HLTError
# from going into Error state themselves
process.options.modulesToCallForTryToContinue = cms.untracked.vstring(
    'hltPrePathStatusError',
    'hltPreDatasetHLTError'
)
@EOF
run_test "${jobLabel}"

# hlt4: hlt3 but with an empty modulesToCallForTryToContinue
jobLabel="hlt4"
cat <<@EOF >> "${tmpfile}"

process.options.modulesToCallForTryToContinue = cms.untracked.vstring()
@EOF
run_test "${jobLabel}"
