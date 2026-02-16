#!/bin/bash -ex

cat <<@EOF >> l1t1.py
import FWCore.ParameterSet.Config as cms

process = cms.Process('TEST')

process.options.numberOfThreads = 1
process.options.numberOfStreams = 0
process.options.wantSummary = False

process.maxEvents.input = 100

# MessageLogger
process.MessageLogger.cerr.FwkReport.reportEvery = 1
process.MessageLogger.L1TGlobalSummary = cms.untracked.PSet()

# Input source
process.source = cms.Source('PoolSource',
    fileNames = cms.untracked.vstring(
        '/store/data/Run2025D/EphemeralHLTPhysics0/RAW/v1/000/394/959/00000/02ab3d20-66ba-4372-8f06-5d09e0848408.root'
    )
)

# EventSetup modules
from Configuration.AlCa.GlobalTag import GlobalTag
process.load('Configuration.StandardSequences.FrontierConditions_GlobalTag_cff')
process.GlobalTag = GlobalTag(process.GlobalTag, '160X_dataRun3_HLT_v1')

process.GlobalParametersRcdSource = cms.ESSource('EmptyESSource',
    recordName = cms.string('L1TGlobalParametersRcd'),
    iovIsRunNotTime = cms.bool(True),
    firstValid = cms.vuint32(1)
)

process.GlobalParameters = cms.ESProducer('StableParametersTrivialProducer',
    NumberPhysTriggers = cms.uint32(512),
    NumberL1Muon = cms.uint32(8),
    NumberL1EGamma = cms.uint32(12),
    NumberL1Jet = cms.uint32(12),
    NumberL1Tau = cms.uint32(12),
    NumberChips = cms.uint32(1),
    PinsOnChip = cms.uint32(512),
    OrderOfChip = cms.vint32(1)
)

# EventData modules
process.gtStage2Digis = cms.EDProducer('L1TRawToDigi',
    FedIds = cms.vint32(1404),
    Setup = cms.string('stage2::GTSetup'),
    FWId = cms.uint32(0),
    DmxFWId = cms.uint32(0),
    FWOverride = cms.bool(False),
    TMTCheck = cms.bool(True),
    CTP7 = cms.untracked.bool(False),
    MTF7 = cms.untracked.bool(False),
    InputLabel = cms.InputTag('rawDataCollector'),
    lenSlinkHeader = cms.untracked.int32(8),
    lenSlinkTrailer = cms.untracked.int32(8),
    lenAMCHeader = cms.untracked.int32(8),
    lenAMCTrailer = cms.untracked.int32(0),
    lenAMC13Header = cms.untracked.int32(8),
    lenAMC13Trailer = cms.untracked.int32(8),
    debug = cms.untracked.bool(False),
    MinFeds = cms.uint32(0)
)

process.gtStage2Digis2 = cms.EDProducer('L1TGlobalProducer',
    MuonInputTag = cms.InputTag('gtStage2Digis:Muon'),
    MuonShowerInputTag = cms.InputTag('gtStage2Digis:MuonShower'),
    EGammaInputTag = cms.InputTag('gtStage2Digis:EGamma'),
    TauInputTag = cms.InputTag('gtStage2Digis:Tau'),
    JetInputTag = cms.InputTag('gtStage2Digis:Jet'),
    EtSumInputTag = cms.InputTag('gtStage2Digis:EtSum'),
    EtSumZdcInputTag = cms.InputTag('gtStage2Digis:EtSumZDC'),
    CICADAInputTag = cms.InputTag('gtStage2Digis:CICADAScore'),
    ExtInputTag = cms.InputTag('gtStage2Digis'),
    AlgoBlkInputTag = cms.InputTag('gtStage2Digis'),
    RequireMenuToMatchAlgoBlkInput = cms.bool(True),
    AlgorithmTriggersUnprescaled = cms.bool(True),
    AlgorithmTriggersUnmasked = cms.bool(True),
    GetPrescaleColumnFromData = cms.bool(True),
    useMuonShowers = cms.bool(True),
    produceAXOL1TLScore = cms.bool(False),
    resetPSCountersEachLumiSec = cms.bool(False),
    semiRandomInitialPSCounters = cms.bool(False),
    ProduceL1GtDaqRecord = cms.bool(True),
    ProduceL1GtObjectMapRecord = cms.bool(True),
    EmulateBxInEvent = cms.int32(1),
    L1DataBxInEvent = cms.int32(5),
    AlternativeNrBxBoardDaq = cms.uint32(0),
    BstLengthBytes = cms.int32(-1),
    PrescaleSet = cms.uint32(1),
    Verbosity = cms.untracked.int32(0),
    PrintL1Menu = cms.untracked.bool(False),
    TriggerMenuLuminosity = cms.string('startup')
)

process.l1tGlobalSummary2 = cms.EDAnalyzer('L1TGlobalSummary',
    AlgInputTag = cms.InputTag('gtStage2Digis2'),
    ExtInputTag = cms.InputTag('gtStage2Digis2'),
    MinBx = cms.int32(0),
    MaxBx = cms.int32(0),
    DumpTrigResults = cms.bool(False),
    DumpRecord = cms.bool(False),
    DumpTrigSummary = cms.bool(True),
    ReadPrescalesFromFile = cms.bool(False),
    psFileName = cms.string('prescale_L1TGlobal.csv'),
    psColumn = cms.int32(0)
)

# Path
process.Path = cms.Path(
    process.gtStage2Digis
  + process.gtStage2Digis2
  + process.l1tGlobalSummary2
)
@EOF

cp l1t1.py l1t2.py
cat <<@EOF >> l1t2.py
process.gtStage2Digis2.RequireMenuToMatchAlgoBlkInput = False

process.GlobalTag.toGet += [cms.PSet(
    record = cms.string('L1TUtmTriggerMenuRcd'),
    tag = cms.string('L1Menu_Collisions2026_v1_0_0_xml')
)]
@EOF

cmsRun l1t1.py 2>&1 | tee -a l1t1.log
cmsRun l1t2.py 2>&1 | tee -a l1t2.log
