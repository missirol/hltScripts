import FWCore.ParameterSet.Config as cms

import argparse
import math
import os
import sys

parser = argparse.ArgumentParser(prog = sys.argv[0],
    description = "Emulate L1T CaloLayer1 and produce DQM outputs for data-emulator comparisons",
    formatter_class = argparse.ArgumentDefaultsHelpFormatter
)

parser.add_argument("-i", "--inputFiles", nargs = "+", required = True,
    help = "List of EDM input files")

parser.add_argument("-l", "--rawDataLabel", default = "rawDataCollector",
    help = "Label of FEDRawCollection in EDM input files")

parser.add_argument("-n", "--maxEvents", type = int, default = -1, help = "Value of process.maxEvents.input")
parser.add_argument("--skipEvents", type = int, default = 0, help = "Value of process.source.skipEvents")
parser.add_argument("-t", "--threads", type = int, default = 1, help = "Value of process.options.numberOfThreads")
parser.add_argument("-s", "--streams", type = int, default = 0, help = "Value of process.options.numberOfStreams")
parser.add_argument("-p", "--processName", default = "TEST", help = "Name of the cms.Process instance")

parser.add_argument("-e", "--report-every", type = int, default = -1,
    help = "Value of process.MessageLogger.cerr.FwkReport.reportEvery")

parser.add_argument("-g", "--globaltag", required = True, help = "Name of the GlobalTag")

parser.add_argument("--ignoreCaloMask", action = 'store_true', default = False,
    help = "Ignore mask bit in ECAL/HCAL trigger primitives")

parser.add_argument("-o", "--outputFile", required = True, help = "Name of DQMIO output file")

parser.add_argument("-c", "--caloParams-cfi", default = None,
    help = 'Argument of process.load to load an instance of the "L1TCaloStage2ParamsESProducer" plugin')

args = parser.parse_args()

process = cms.Process(args.processName)

process.maxEvents.input = args.maxEvents

process.options.numberOfThreads = args.threads
process.options.numberOfStreams = args.streams
process.options.numberOfConcurrentLuminosityBlocks = 1

process.options.wantSummary = False

process.load("FWCore.MessageService.MessageLogger_cfi")
process.MessageLogger.cerr.FwkReport.limit = -1
process.MessageLogger.cerr.FwkReport.reportEvery = args.report_every if args.report_every > 0 \
    else int(math.pow(10, max(0, int(math.log10(args.maxEvents)) - 2)) if args.maxEvents > 0 else 100)

from IOPool.Input.PoolSource import PoolSource
process.source = PoolSource(
    fileNames = args.inputFiles,
    skipEvents = args.skipEvents
)

process.load("Configuration.StandardSequences.FrontierConditions_GlobalTag_cff")
from Configuration.AlCa.GlobalTag import GlobalTag as customiseGlobalTag
process.GlobalTag = customiseGlobalTag(process.GlobalTag, globaltag = args.globaltag)

if args.caloParams_cfi:
    process.load(f'L1Trigger.L1TCalorimeter.{args.caloParams_cfi}')

process.fatEventFilter = cms.EDFilter("HLTL1NumberFilter",
    fedIds = cms.vint32(1024),
    invert = cms.bool(False),
    period = cms.uint32(107),
    rawInput = cms.InputTag(args.rawDataLabel)
)

process.caloStage2Digis = cms.EDProducer("L1TRawToDigi",
    FWId = cms.uint32(0),
    FWOverride = cms.bool(False),
    FedIds = cms.vint32(1360, 1366),
    InputLabel = cms.InputTag(args.rawDataLabel),
    Setup = cms.string("stage2::CaloSetup"),
    TMTCheck = cms.bool(True)
)

process.caloLayer1Digis = cms.EDProducer("L1TRawToDigi",
    CTP7 = cms.untracked.bool(True),
    FWId = cms.uint32(305419896),
    FedIds = cms.vint32(1354, 1356, 1358),
    InputLabel = cms.InputTag(args.rawDataLabel),
    Setup = cms.string("stage2::CaloLayer1Setup"),
    debug = cms.untracked.bool(False)
)

process.valCaloStage2Layer1Digis = cms.EDProducer("L1TCaloLayer1",
    ecalToken = cms.InputTag("caloLayer1Digis"),
    firmwareVersion = cms.int32(3),
    hcalToken = cms.InputTag("caloLayer1Digis"),
    unpackEcalMask = cms.bool(not args.ignoreCaloMask),
    unpackHcalMask = cms.bool(not args.ignoreCaloMask),
    useCalib = cms.bool(True),
    useECALLUT = cms.bool(True),
    useHCALFBLUT = cms.bool(False),
    useHCALLUT = cms.bool(True),
    useHFLUT = cms.bool(True),
    useLSB = cms.bool(True),
    verbose = cms.untracked.bool(False)
)

process.l1tdeStage2CaloLayer1 = cms.EDProducer("L1TdeStage2CaloLayer1",
    dataSource = cms.InputTag("caloStage2Digis","CaloTower"),
    emulSource = cms.InputTag("valCaloStage2Layer1Digis"),
    fedRawDataLabel = cms.InputTag(args.rawDataLabel),
    histFolder = cms.string("L1TEMU/L1TdeStage2CaloLayer1")
)

process.DQMPath = cms.Path(
    process.fatEventFilter
  + process.caloStage2Digis
  + process.caloLayer1Digis
  + process.valCaloStage2Layer1Digis
  + process.l1tdeStage2CaloLayer1
)

process.dqmOutput = cms.OutputModule("DQMRootOutputModule",
    dataset = cms.untracked.PSet(
        dataTier = cms.untracked.string("DQMIO"),
        filterName = cms.untracked.string("")
    ),
    fileName = cms.untracked.string(args.outputFile),
    outputCommands = cms.untracked.vstring(
        "drop *",
        "keep *_MEtoEDMConverter_*_*"
    ),
    splitLevel = cms.untracked.int32(0)
)

process.DQMStore = cms.Service("DQMStore",
    MEsToSave = cms.untracked.vstring(),
    assertLegacySafe = cms.untracked.bool(False),
    collateHistograms = cms.untracked.bool(True),
    enableMultiThread = cms.untracked.bool(True),
    onlineMode = cms.untracked.bool(False),
    saveByLumi = cms.untracked.bool(False),
    trackME = cms.untracked.string(''),
    verbose = cms.untracked.int32(0)
)

process.CaloGeometryBuilder = cms.ESProducer("CaloGeometryBuilder",
    SelectedCalos = cms.vstring(
        'HCAL',
        'ZDC',
        'EcalBarrel',
        'EcalEndcap',
        'EcalPreshower',
        'TOWER'
    )
)

process.HcalTrigTowerGeometryESProducer = cms.ESProducer("HcalTrigTowerGeometryESProducer")

process.hcalTopologyIdeal = cms.ESProducer("HcalTopologyIdealEP",
    Exclude = cms.untracked.string(''),
    MergePosition = cms.untracked.bool(False),
    appendToDataLabel = cms.string('')
)

process.hcalDDDRecConstants = cms.ESProducer("HcalDDDRecConstantsESModule",
    appendToDataLabel = cms.string('')
)

process.hcalDDDSimConstants = cms.ESProducer("HcalDDDSimConstantsESModule",
    appendToDataLabel = cms.string('')
)

process.CaloTPGTranscoder = cms.ESProducer("CaloTPGTranscoderULUTs",
    LUTfactor = cms.vint32(1, 2, 5, 0),
    RCTLSB = cms.double(0.25),
    ZS = cms.vint32(4, 2, 1, 0),
    hcalLUT1 = cms.FileInPath('CalibCalorimetry/CaloTPG/data/outputLUTtranscoder_physics.dat'),
    hcalLUT2 = cms.FileInPath('CalibCalorimetry/CaloTPG/data/TPGcalcDecompress2.txt'),
    ietaLowerBound = cms.vint32(1, 18, 27, 29),
    ietaUpperBound = cms.vint32(17, 26, 28, 32),
    linearLUTs = cms.bool(True),
    nominal_gain = cms.double(0.177),
    read_Ascii_Compression_LUTs = cms.bool(False),
    read_Ascii_RCT_LUTs = cms.bool(False),
    tpScales = cms.PSet(
        HBHE = cms.PSet(
            LSBQIE11 = cms.double(0.0625),
            LSBQIE11Overlap = cms.double(0.0625),
            LSBQIE8 = cms.double(0.125)
        ),
        HF = cms.PSet(
            NCTShift = cms.int32(2),
            RCTShift = cms.int32(3)
        )
    )
)

process.DQMEndPath = cms.EndPath(process.dqmOutput)

process.schedule = cms.Schedule(*[ process.DQMPath, process.DQMEndPath ])
