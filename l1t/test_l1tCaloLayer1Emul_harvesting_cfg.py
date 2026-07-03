import FWCore.ParameterSet.Config as cms

import argparse
import sys

parser = argparse.ArgumentParser(
    prog = "cmsRun " + sys.argv[0] + " --",
    description = "Configuration file to run the DQMFileSaver on DQMIO input files.",
    formatter_class = argparse.ArgumentDefaultsHelpFormatter
)

parser.add_argument("-t", "--nThreads", type = int, help = "Number of threads", default = 1)
parser.add_argument("-s", "--nStreams", type = int, help = "Number of EDM streams", default = 0)
parser.add_argument("-i", "--inputFiles", nargs = "+", help = "List of DQMIO input files", default = ["file:DQMIO.root"])
parser.add_argument("-o", "--outputFileLabel", help = "Value of dqmSaver.workflow", default = "/XXX/YYY/ZZZ")

args = parser.parse_args()

process = cms.Process("HARVESTING")

process.options.numberOfThreads = args.nThreads
process.options.numberOfStreams = args.nStreams
process.options.numberOfConcurrentLuminosityBlocks = 1

# Source (DQM input)
process.source = cms.Source("DQMRootSource",
    fileNames = cms.untracked.vstring(args.inputFiles)
)

# DQMStore (Service)
process.load("DQMServices.Core.DQMStore_cfi")

# Output module (file in ROOT format)
from DQMServices.Components.DQMFileSaver_cfi import dqmSaver as _dqmSaver
process.dqmSaver = _dqmSaver.clone(workflow = args.outputFileLabel)

# EndPath
process.DQMSaverEndPath = cms.EndPath(process.dqmSaver)
