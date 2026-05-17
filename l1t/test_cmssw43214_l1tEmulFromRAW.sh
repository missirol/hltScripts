#!/bin/bash

cmsDriver.py bar \
 --no_output --no_exec --dump_python -n 1000 \
 --filein /store/group/tsg/STORM/RAW/Run2024J_HIEphemeralHLTPhysics_run387440/235844d9-333c-43a9-9c92-b1ce47ce19d1.root \
 --era Run3_2024 --data --conditions 150X_dataRun3_HLT_v1 \
 -s RAW2DIGI --python_filename l1t_L1TReEmulFromRAW_cfg.py \
 --customise L1Trigger/Configuration/customiseReEmul.L1TReEmulFromRAW

cat <<@EOF >> l1t_L1TReEmulFromRAW_cfg.py

process.options.numberOfThreads = 1
process.options.numberOfStreams = 0

process.options.wantSummary = True
process.MessageLogger.L1TGlobalSummary = cms.untracked.PSet()

process.l1tGtStage2Digis1 = cms.EDProducer( "L1TRawToDigi",
    FedIds = cms.vint32( 1404 ),
    Setup = cms.string( "stage2::GTSetup" ),
    FWId = cms.uint32( 0 ),
    DmxFWId = cms.uint32( 0 ),
    FWOverride = cms.bool( False ),
    TMTCheck = cms.bool( True ),
    CTP7 = cms.untracked.bool( False ),
    MTF7 = cms.untracked.bool( False ),
    InputLabel = cms.InputTag( "rawDataCollector::@skipCurrentProcess" ),
    lenSlinkHeader = cms.untracked.int32( 8 ),
    lenSlinkTrailer = cms.untracked.int32( 8 ),
    lenAMCHeader = cms.untracked.int32( 8 ),
    lenAMCTrailer = cms.untracked.int32( 0 ),
    lenAMC13Header = cms.untracked.int32( 8 ),
    lenAMC13Trailer = cms.untracked.int32( 8 ),
    debug = cms.untracked.bool( False ),
    MinFeds = cms.uint32( 0 )
)

process.l1tGlobalSummary1 = cms.EDAnalyzer( "L1TGlobalSummary",
    AlgInputTag = cms.InputTag( "l1tGtStage2Digis1" ),
    ExtInputTag = cms.InputTag( "l1tGtStage2Digis1" ),
    MinBx = cms.int32( 0 ),
    MaxBx = cms.int32( 0 ),
    DumpTrigResults = cms.bool( False ),
    DumpRecord = cms.bool( False ),
    DumpTrigSummary = cms.bool( True ),
    ReadPrescalesFromFile = cms.bool( False ),
    psFileName = cms.string( "" ),
    psColumn = cms.int32( 0 )
)

process.l1tGlobalSummary2 = process.l1tGlobalSummary1.clone(
    AlgInputTag = "simGtStage2Digis::@currentProcess",
    ExtInputTag = "simGtStage2Digis::@currentProcess",
)

process.L1TMonitorPath = cms.Path(
    process.l1tGtStage2Digis1
  + process.l1tGlobalSummary1
  + process.l1tGlobalSummary2
)

process.schedule.append( process.L1TMonitorPath )
@EOF

cmsRun l1t_L1TReEmulFromRAW_cfg.py &> l1t_L1TReEmulFromRAW_cfg.log
grep L1_ZDC l1t_L1TReEmulFromRAW_cfg.log
