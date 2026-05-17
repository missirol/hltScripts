import FWCore.ParameterSet.Config as cms

import argparse
import sys
import math
import glob

parser = argparse.ArgumentParser(prog=sys.argv[0], description='Test of the L1-uGT emulator')
parser.add_argument('-n', '--maxEvents', type=int, help='Value of process.maxEvents.input', default=-1)
parser.add_argument('-t', '--threads', type=int, help='Value of process.options.numberOfThreads', default=1)
parser.add_argument('-s', '--streams', type=int, help='Value of process.options.numberOfStreams', default=0)
parser.add_argument('-l', '--rawDataLabel', type=str, help='Label for the FEDRawDataCollection input product', default='rawDataCollector')
parser.add_argument('-m', '--moduleAllocMonitorOutput', type=str, help='Name of output file of ModuleAllocMonitor service', default=None)
args = parser.parse_args()

process = cms.Process('TEST')

process.options.numberOfThreads = args.threads
process.options.numberOfStreams = args.streams
process.options.wantSummary = False

process.maxEvents.input = args.maxEvents

# ModuleAllocMonitor
if args.moduleAllocMonitorOutput:
    process.add_(cms.Service("ModuleAllocMonitor",
        fileName = cms.untracked.string(args.moduleAllocMonitorOutput)
    ))

# FastTimerService
process.load("HLTrigger.Timer.FastTimerService_cfi")
process.FastTimerService.printEventSummary = False
process.FastTimerService.printRunSummary = False
process.FastTimerService.printJobSummary = True

# MessageLogger
process.load('FWCore.MessageService.MessageLogger_cfi')
process.MessageLogger.cerr.FwkReport.reportEvery = int(math.pow(10, max(0, int(math.log10(args.maxEvents)) - 1)) if args.maxEvents > 0 else 100)
process.MessageLogger.L1TGlobalSummary = cms.untracked.PSet()
process.MessageLogger.FastReport = cms.untracked.PSet()

# Input source
process.source = cms.Source('PoolSource',
    fileNames = cms.untracked.vstring(
        '/store/user/cmsbuild/store/data/Run2025D/EphemeralHLTPhysics0/RAW/v1/000/394/959/00000/02ab3d20-66ba-4372-8f06-5d09e0848408.root'
    )
)

# EventSetup modules
from Configuration.AlCa.GlobalTag import GlobalTag
process.load('Configuration.StandardSequences.FrontierConditions_GlobalTag_cff')
process.GlobalTag = GlobalTag(process.GlobalTag, '150X_dataRun3_HLT_v1')

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
    InputLabel = cms.InputTag(args.rawDataLabel),
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
    AlgorithmTriggersUnprescaled = cms.bool(False),
    AlgorithmTriggersUnmasked = cms.bool(False),
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

process.l1tGlobalSummary1 = cms.EDAnalyzer('L1TGlobalSummary',
    AlgInputTag = cms.InputTag('gtStage2Digis'),
    ExtInputTag = cms.InputTag('gtStage2Digis'),
    MinBx = cms.int32(0),
    MaxBx = cms.int32(0),
    DumpTrigResults = cms.bool(False),
    DumpRecord = cms.bool(False),
    DumpTrigSummary = cms.bool(True),
    ReadPrescalesFromFile = cms.bool(False),
    psFileName = cms.string('prescale_L1TGlobal.csv'),
    psColumn = cms.int32(0)
)

process.l1tGlobalSummary2 = process.l1tGlobalSummary1.clone(
    AlgInputTag = 'gtStage2Digis2',
    ExtInputTag = 'gtStage2Digis2'
)

# Path
process.Path = cms.Path(
    process.gtStage2Digis
  + process.gtStage2Digis2
  + process.l1tGlobalSummary1
  + process.l1tGlobalSummary2
)
