import FWCore.ParameterSet.Config as cms

badEventID = cms.untracked.EventID(360761, 112, 32415596)
inputFile = 'file:/eos/cms/store/user/cmsbuild/store/data/Run2022F/EphemeralHLTPhysics0/RAW/v1/000/360/761/00000/f9db72a8-c646-48c1-9d64-edf91c7de7cf.root'
nStreams = 1

nEvents = 10
nSkipEvents = 0 #4

process = cms.Process("TEST")

process.source = cms.Source("PoolSource",
    fileNames = cms.untracked.vstring( inputFile ),
    skipEvents = cms.untracked.uint32( nSkipEvents ),
)

process.maxEvents = cms.untracked.PSet(
    input = cms.untracked.int32(nEvents)
)

process.options = cms.untracked.PSet(
    numberOfThreads = cms.untracked.uint32(nStreams),
    numberOfStreams = cms.untracked.uint32(nStreams),
    numberOfConcurrentRuns = cms.untracked.uint32(1),
    numberOfConcurrentLuminosityBlocks = cms.untracked.uint32(2)
)

process.load("FWCore.PrescaleService.PrescaleService_cfi")
process.PrescaleService.lvl1Labels = ['10E30','10E31','10E32']
process.PrescaleService.lvl1DefaultLabel = '10E31'
process.PrescaleService.prescaleTable = cms.VPSet(
    cms.PSet(
        pathName = cms.string('path1'),
        prescales = cms.vuint32(2, 5, 10)
    ), 
    cms.PSet(
        pathName = cms.string('endpath1'),
        prescales = cms.vuint32(5, 10, 20)
    )
)

process.throwException11 = cms.EDProducer("ExceptionThrowingProducer",
    eventIDThrowOnEvent = badEventID,
)

# Below, the EventID's are selected such that it is likely that in the process
# configured by this file that more than 1 run, more than 1 lumi and more than 1 event
# (stream) will be in flight when the exception is thrown.

process.throwException12 = process.throwException11.clone()
process.throwException21 = process.throwException11.clone()
process.throwException22 = process.throwException11.clone()

process.hltPrePath1 = cms.EDFilter( "HLTPrescaler",
    offset = cms.uint32( 0 ),
    L1GtReadoutRecordTag = cms.InputTag( "hltGtStage2Digis" )
)

process.hltPreEndPath1 = process.hltPrePath1.clone()

process.path1 = cms.Path(
    process.throwException11
  + process.hltPrePath1
  + process.throwException12
)

process.endpath1 = cms.EndPath(
    process.throwException21
  + process.hltPreEndPath1
  + process.throwException22
)

process.options.wantSummary = True
process.options.SkipEvent = cms.untracked.vstring('IntentionalTestException')
