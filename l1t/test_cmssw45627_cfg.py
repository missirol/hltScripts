import FWCore.ParameterSet.Config as cms

from Configuration.Eras.Era_Run3_cff import Run3

process = cms.Process('TEST', Run3)

# import of standard configurations
process.load('Configuration.StandardSequences.Services_cff')
process.load('Configuration.StandardSequences.GeometryRecoDB_cff')
process.load('Configuration.StandardSequences.MagneticField_cff')
process.load('Configuration.StandardSequences.FrontierConditions_GlobalTag_cff')

process.maxEvents.input = 10

process.options.numberOfThreads = 1
process.options.numberOfStreams = 0

from Configuration.AlCa.GlobalTag import GlobalTag
process.GlobalTag = GlobalTag(process.GlobalTag, '140X_dataRun3_HLT_v3', '')

process.source = cms.Source('PoolSource',
    fileNames = cms.untracked.vstring(
        'root://eoscms.cern.ch//eos/cms/store/user/cmsbuild/store/data/Run2024E/ZeroBias/RAW/v1/000/381/380/00000/1dd4eedf-f2a0-49d7-8924-a5bf01904533.root',
    )
)

def unpackAndRepackL1uGT(process, inputLabel, unpackedLabel, repackedLabel):

    setattr(process, unpackedLabel, cms.EDProducer('L1TRawToDigi',
        InputLabel = cms.InputTag(inputLabel),
        FedIds = cms.vint32(1404),
        Setup = cms.string('stage2::GTSetup')
    ))

    setattr(process, repackedLabel, cms.EDProducer('L1TDigiToRaw',
        GtInputTag = cms.InputTag(unpackedLabel),
        ExtInputTag = cms.InputTag(unpackedLabel),
        MuonInputTag = cms.InputTag(unpackedLabel,'Muon'),
        ShowerInputLabel = cms.InputTag(unpackedLabel,'MuonShower'),
        EGammaInputTag = cms.InputTag(unpackedLabel,'EGamma'),
        JetInputTag = cms.InputTag(unpackedLabel,'Jet'),
        TauInputTag = cms.InputTag(unpackedLabel,'Tau'),
        EtSumInputTag = cms.InputTag(unpackedLabel,'EtSum'),
        EtSumZDCInputTag  = cms.InputTag(unpackedLabel,'EtSumZDC'),
        Setup = cms.string('stage2::GTSetup'),
        FWId = cms.uint32(4432),
        FedId = cms.int32(1404),
        lenSlinkHeader = cms.untracked.int32(8),
        lenSlinkTrailer = cms.untracked.int32(8)
    ))

    return process

process.l1tGtStage2RawData0 = cms.EDProducer('EvFFEDSelector',
    inputTag = cms.InputTag('rawDataCollector'),
    fedList = cms.vuint32(1404)
)

process = unpackAndRepackL1uGT(process, 'l1tGtStage2RawData0', 'l1tGtStage2Digis1', 'l1tGtStage2RawData1')
process = unpackAndRepackL1uGT(process, 'l1tGtStage2RawData1', 'l1tGtStage2Digis2', 'l1tGtStage2RawData2')

process.seq = cms.Sequence(
    process.l1tGtStage2RawData0
  + process.l1tGtStage2Digis1
  + process.l1tGtStage2RawData1
  + process.l1tGtStage2Digis2
  + process.l1tGtStage2RawData2
)

process.path = cms.Path(process.seq)

process.output = cms.OutputModule('PoolOutputModule',
    fileName = cms.untracked.string('file:tmp.root'),
    outputCommands = cms.untracked.vstring(
        'drop *',
        'keep *_rawDataCollector_*_*',
        'keep *_l1tGtStage2RawData0_*_*',
        'keep *_l1tGtStage2RawData1_*_*',
        'keep *_l1tGtStage2RawData2_*_*',
        'keep *_l1tGtStage2Digis1_*_*',
        'keep *_l1tGtStage2Digis2_*_*',
    )
)

process.endpath = cms.EndPath(process.output)
