import argparse
import glob
import math
import os
import sys

import FWCore.ParameterSet.Config as cms

parser = argparse.ArgumentParser(prog=sys.argv[0],
    formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    description='Unpack data of the L1-uGT test crate (FED 1405).')

parser.add_argument('-n', '--maxEvents', type=int, help='Value of process.maxEvents.input', default=-1)
parser.add_argument('-t', '--threads', type=int, help='Value of process.options.numberOfThreads', default=1)
parser.add_argument('-s', '--streams', type=int, help='Value of process.options.numberOfStreams', default=0)
parser.add_argument('-p', '--process-name', type=str, help='Name of the cms.Process instance', default='TEST')
parser.add_argument('--skipEvents', type=int, help='Value of process.source.skipEvents', default=0)

parser.add_argument('-e', '--report-every', type=int,
    help='Value of process.MessageLogger.cerr.FwkReport.reportEvery (if not above 0, it is determined based on maxEvents)', default=-1)

parser.add_argument('-i', '--inputFiles', nargs='+',
    help='List of EDM input files ("file:" prefix added automatically for local files; arguments passed to glob for wildcard resolution)',
    default=['/eos/cms/tier0/store/data/Run2026D/L1Accept/RAW/v*/*/403/894/*/*.root'])

parser.add_argument('-l', '--FEDRawDataLabel', type=str,
    help='Label of the FEDRawDataCollection containing data from the uGT test crate (FED 1405)', default='hltFEDSelectorL1uGTTest')

group = parser.add_mutually_exclusive_group()
group.add_argument('-o', '--output-filename', type=str, help='Name of the output file', default=None)
group.add_argument('--no-output', dest='output_filename', action='store_const', const=None, help='Do not produce an output file')

args = parser.parse_args()

process = cms.Process(args.process_name)

process.options.numberOfThreads = args.threads
process.options.numberOfStreams = args.streams
process.options.wantSummary = True

process.maxEvents.input = args.maxEvents

# MessageLogger
process.load('FWCore.MessageService.MessageLogger_cfi')
process.MessageLogger.cerr.FwkReport.limit = -1
process.MessageLogger.cerr.FwkReport.reportEvery = args.report_every if args.report_every > 0 \
    else int(math.pow(10, max(0, int(math.log10(args.maxEvents)) - 2)) if args.maxEvents > 0 else 100)

# Input source
_fileNames = []
for fileName_i in args.inputFiles:
    _fileNames += [f'file:{file_i}' if os.path.isfile(file_i) else file_i for file_i in sorted(list(set(glob.glob(fileName_i))))]

from IOPool.Input.PoolSource import PoolSource
process.source = PoolSource(
    fileNames = _fileNames,
    skipEvents = args.skipEvents
)

# EventData Modules and Paths
from EventFilter.L1TRawToDigi.L1TRawToDigi import L1TRawToDigi
process.gtStage2DigisTest = L1TRawToDigi(
    FedIds = [1405],
    Setup = 'stage2::GTSetup',
    InputLabel = args.FEDRawDataLabel,
)

process.UnpackTestDataPath = cms.Path(
    process.gtStage2DigisTest
)

# Output Module and EndPath
if args.output_filename != None:
    from IOPool.Output.PoolOutputModule import PoolOutputModule
    process.outputModule = PoolOutputModule(
        fileName = args.output_filename,
        outputCommands = [
            'drop *',
            'keep *_gtStage2DigisTest_*_*',
        ],
    )

    process.OutputEndPath = cms.EndPath(process.outputModule)
