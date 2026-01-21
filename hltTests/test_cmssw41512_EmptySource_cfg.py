import FWCore.ParameterSet.Config as cms

badEventID = cms.untracked.EventID(1, 1, 1)

nStreams = 1
nRuns = 1
nLumisPerRun = 1
nEventsPerLumi = 1

nEventsPerRun = nLumisPerRun*nEventsPerLumi
nLumis = nRuns*nLumisPerRun
nEvents = nRuns*nEventsPerRun

process = cms.Process("TEST")

process.source = cms.Source("EmptySource",
    firstRun = cms.untracked.uint32(1),
    firstLuminosityBlock = cms.untracked.uint32(1),
    firstEvent = cms.untracked.uint32(1),
    numberEventsInLuminosityBlock = cms.untracked.uint32(nEventsPerLumi),
    numberEventsInRun = cms.untracked.uint32(nEventsPerRun),
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

process.throwException11 = cms.EDProducer("ExceptionThrowingProducer",
    eventIDThrowOnEvent = badEventID
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
#  + process.throwException12
)

process.path2 = cms.Path(
    process.throwException11
)

process.endpath1 = cms.EndPath(
#    process.throwException21
#  + process.hltPreEndPath1
#  + process.throwException22
)

process.outputPath = cms.FinalPath

process.options.wantSummary = True
process.options.SkipEvent = cms.untracked.vstring('IntentionalTestException')
