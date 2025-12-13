import argparse
import sys
import math
import glob

import FWCore.ParameterSet.Config as cms

parser = argparse.ArgumentParser(prog=sys.argv[0],
    formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    description='Store events with L1-uGT data-emulator mismatches for selected L1T algorithms.')

parser.add_argument('-n', '--maxEvents', type=int, help='Value of process.maxEvents.input', default=-1)
parser.add_argument('-t', '--threads', type=int, help='Value of process.options.numberOfThreads', default=1)
parser.add_argument('-s', '--streams', type=int, help='Value of process.options.numberOfStreams', default=0)
parser.add_argument('-o', '--output-filename', type=str, help='Name of the output file', default='tmp.root')

parser.add_argument('-f', '--fileNames', nargs='+',
    help='List of EDM input files ("file:" prefix added automatically for local files; arguments passed to glob for wildcard resolution)',
    default=['/eos/cms/store/data/Run2025F/HLTPhysics/RAW/*/*/397/638/*/*.root'])

parser.add_argument('-a', '--l1t-algorithms', nargs='+',
    help='List of L1T algorithms',
    default=['L1_TripleMu_3SQ_2p5SQ_0_Mass_Max12', 'L1_TripleMu_3SQ_2p5SQ_0_OS_Mass_Max12', 'L1_TripleMu_4SQ_2p5SQ_0_OS_Mass_Max12'])

args = parser.parse_args()

process = cms.Process('TEST')

process.options.numberOfThreads = args.threads
process.options.numberOfStreams = args.streams
process.options.wantSummary = True

process.maxEvents.input = args.maxEvents

# MessageLogger
process.load('FWCore.MessageService.MessageLogger_cfi')
process.MessageLogger.cerr.FwkReport.reportEvery = \
    int(math.pow(10, max(0, int(math.log10(args.maxEvents)) - 2)) if args.maxEvents > 0 else 100)

# Input source
_fileNames = []
for fileName_i in args.fileNames:
    _fileNames += [f'file:{file_i}' if os.path.isfile(file_i) else file_i for file_i in sorted(list(set(glob.glob(fileName_i))))]

from IOPool.Input.PoolSource import PoolSource
process.source = PoolSource(fileNames = _fileNames)

# EventSetup Modules
from Configuration.AlCa.GlobalTag import GlobalTag
process.load('Configuration.StandardSequences.FrontierConditions_GlobalTag_cff')
process.GlobalTag = GlobalTag(process.GlobalTag, '150X_dataRun3_HLT_v1')

from FWCore.Modules.EmptyESSource import EmptyESSource
process.GlobalParametersRcdSource = EmptyESSource(
    recordName = 'L1TGlobalParametersRcd',
    firstValid = 1
)

from L1Trigger.L1TGlobal.StableParametersTrivialProducer import StableParametersTrivialProducer
process.GlobalParameters = StableParametersTrivialProducer(
    NumberL1Muon = 8,
    NumberL1Tau = 12,
    NumberChips = 1
)

# EventData Modules and Paths
from EventFilter.L1TRawToDigi.L1TRawToDigi import L1TRawToDigi
process.gtStage2Digis = L1TRawToDigi(
    FedIds = [1404],
    Setup = 'stage2::GTSetup'
)

from L1Trigger.L1TGlobal.L1TGlobalProducer import L1TGlobalProducer
process.gtStage2Digis2 = L1TGlobalProducer(
    MuonInputTag = 'gtStage2Digis:Muon',
    MuonShowerInputTag = 'gtStage2Digis:MuonShower',
    EGammaInputTag = 'gtStage2Digis:EGamma',
    TauInputTag = 'gtStage2Digis:Tau',
    JetInputTag = 'gtStage2Digis:Jet',
    EtSumInputTag = 'gtStage2Digis:EtSum',
    EtSumZdcInputTag = 'gtStage2Digis:EtSumZDC',
    CICADAInputTag = 'gtStage2Digis:CICADAScore',
    ExtInputTag = 'gtStage2Digis',
    AlgoBlkInputTag = 'gtStage2Digis',
    AlgorithmTriggersUnprescaled = True,
    AlgorithmTriggersUnmasked = True,
    useMuonShowers = True,
)

from HLTrigger.HLTfilters.TriggerResultsFilter import TriggerResultsFilter
_triggerResultsFilter = TriggerResultsFilter(
    usePathStatus = False,
    hltResults = '',
    l1tResults = '',
    l1tIgnoreMaskAndPrescale = True,
    triggerConditions = []
)

for l1tAlgoIdx,l1tAlgo in enumerate(args.l1t_algorithms):

    setattr(process, f'testL1TDigisFilter{l1tAlgoIdx}', _triggerResultsFilter.clone(
        l1tResults = 'gtStage2Digis',
        triggerConditions = [l1tAlgo]
    ))

    setattr(process, f'TestL1TDigisPath{l1tAlgoIdx}', cms.Path(
        process.gtStage2Digis
      + getattr(process, f'testL1TDigisFilter{l1tAlgoIdx}')
    ))

    setattr(process, f'testL1uGTEmuFilter{l1tAlgoIdx}', _triggerResultsFilter.clone(
        l1tResults = 'gtStage2Digis2',
        triggerConditions = [l1tAlgo]
    ))

    setattr(process, f'TestL1uGTEmuPath{l1tAlgoIdx}', cms.Path(
        process.gtStage2Digis
      + process.gtStage2Digis2
      + getattr(process, f'testL1uGTEmuFilter{l1tAlgoIdx}')
    ))

    setattr(process, f'testL1TMismatchFilter{l1tAlgoIdx}', _triggerResultsFilter.clone(
        usePathStatus = True,
        triggerConditions = [f'TestL1TDigisPath{l1tAlgoIdx} XOR TestL1uGTEmuPath{l1tAlgoIdx}']
    ))

    setattr(process, f'TestL1TMismatchPath{l1tAlgoIdx}', cms.Path(
        getattr(process, f'testL1TMismatchFilter{l1tAlgoIdx}')
    ))

process.testL1TMismatchFilterAll = _triggerResultsFilter.clone(
    usePathStatus = True,
    triggerConditions = ['TestL1TMismatchPath?']
)

process.TestL1TMismatchPathAll = cms.Path(
    process.testL1TMismatchFilterAll
)

# Output Module and EndPath
from IOPool.Output.PoolOutputModule import PoolOutputModule
process.outputModule = PoolOutputModule(
    fileName = args.output_filename,
    SelectEvents = dict(SelectEvents = ['TestL1TMismatchPathAll'])
)

process.OutputEndPath = cms.EndPath(process.outputModule)
