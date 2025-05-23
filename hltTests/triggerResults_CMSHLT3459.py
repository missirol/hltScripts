#!/usr/bin/env python3
import os
import sys
import multiprocessing

def execmd(cmd):
    return os.system(cmd)

if __name__ == '__main__':

    ###
    ### parameters
    ###
    minRunNumber = 151
    maxRunNumber = 200
    numEventsPerJob = -1

    numThreadsPerJobs = 32
    numStreamsPerJobs = 24

    eosDirs = [f'/eos/cms/store/data/Run2024I/EphemeralHLTPhysics{foo}/RAW/v1/000/386/593/00000' for foo in range(7)]

    hltLabel = sys.argv[1]

    hltMenu = '/dev/CMSSW_15_0_0/GRun/V60'

    hltGetCmd = f"""
https_proxy=http://cmsproxy.cms:3128/ \
hltGetConfiguration {hltMenu} \
  --process HLTX \
  --globaltag 150X_dataRun3_HLT_forTriggerStudies_v4 \
  --data \
  --no-prescale \
  --output minimal \
  --max-events {numEventsPerJob} \
  > {hltLabel}.py && \
cat <<@EOF >> {hltLabel}.py
process.options.numberOfThreads = {numThreadsPerJobs}
process.options.numberOfStreams = {numStreamsPerJobs}
process.options.wantSummary = False

for foo in ['HLTAnalyzerEndpath', 'dqmOutput', 'MessageLogger']:
    if hasattr(process, foo):
        process.__delattr__(foo)

process.load('FWCore.MessageLogger.MessageLogger_cfi')

process.hltOutputMinimal.outputCommands = [
    'drop *',
    'keep edmTriggerResults_*_*_HLTX',
]

process.options.accelerators = ['cpu']
@EOF
"""

    customizeHLTfor2024L1TMenu = """
def customizeHLTfor2024L1TMenu(process):
    seed_replacements = {

        'L1_SingleMu5_BMTF' : 'L1_AlwaysTrue',
        'L1_SingleMu13_SQ14_BMTF': 'L1_AlwaysTrue',

        'L1_AXO_Medium' : 'L1_AXO_Nominal',
        'L1_AXO_VVTight': 'L1_AlwaysTrue',
        'L1_AXO_VVVTight': 'L1_AlwaysTrue',

        'L1_CICADA_VVTight': 'L1_AlwaysTrue',
        'L1_CICADA_VVVTight': 'L1_AlwaysTrue',
        'L1_CICADA_VVVVTight': 'L1_AlwaysTrue',

        'L1_DoubleTau_Iso34_Iso26_er2p1_Jet55_RmOvlp_dR0p5': 'L1_DoubleIsoTau26er2p1_Jet55_RmOvlp_dR0p5 OR L1_DoubleIsoTau26er2p1_Jet70_RmOvlp_dR0p5',
        'L1_DoubleTau_Iso38_Iso26_er2p1_Jet55_RmOvlp_dR0p5': 'L1_DoubleIsoTau26er2p1_Jet55_RmOvlp_dR0p5 OR L1_DoubleIsoTau26er2p1_Jet70_RmOvlp_dR0p5',
        'L1_DoubleTau_Iso40_Iso26_er2p1_Jet55_RmOvlp_dR0p5': 'L1_DoubleIsoTau26er2p1_Jet55_RmOvlp_dR0p5 OR L1_DoubleIsoTau26er2p1_Jet70_RmOvlp_dR0p5',

        'L1_DoubleEG15_11_er1p2_dR_Max0p6': 'L1_DoubleEG11_er1p2_dR_Max0p6',
        'L1_DoubleEG16_11_er1p2_dR_Max0p6': 'L1_DoubleEG11_er1p2_dR_Max0p6',
        'L1_DoubleEG17_11_er1p2_dR_Max0p6': 'L1_DoubleEG11_er1p2_dR_Max0p6',

        'L1_DoubleEG15_er1p5_dEta_Max1p5': 'L1_AlwaysTrue',
        'L1_DoubleEG16_er1p5_dEta_Max1p5': 'L1_AlwaysTrue',
        'L1_DoubleEG17_er1p5_dEta_Max1p5': 'L1_AlwaysTrue',

        'L1_DoubleJet_110_35_DoubleJet35_Mass_Min1000': 'L1_AlwaysTrue',
        'L1_DoubleJet_110_35_DoubleJet35_Mass_Min1100': 'L1_AlwaysTrue',
        'L1_DoubleJet_110_35_DoubleJet35_Mass_Min1200': 'L1_AlwaysTrue',
        'L1_DoubleJet45_Mass_Min700_IsoTau45er2p1_RmOvlp_dR0p5': 'L1_AlwaysTrue',
        'L1_DoubleJet45_Mass_Min800_IsoTau45er2p1_RmOvlp_dR0p5': 'L1_AlwaysTrue',
        'L1_DoubleJet_65_35_DoubleJet35_Mass_Min750_DoubleJetCentral50': 'L1_AlwaysTrue',
        'L1_DoubleJet_65_35_DoubleJet35_Mass_Min850_DoubleJetCentral50': 'L1_AlwaysTrue',
        'L1_DoubleJet_65_35_DoubleJet35_Mass_Min950_DoubleJetCentral50': 'L1_AlwaysTrue',
        'L1_DoubleJet45_Mass_Min700_LooseIsoEG20er2p1_RmOvlp_dR0p2': 'L1_AlwaysTrue',
        'L1_DoubleJet45_Mass_Min800_LooseIsoEG20er2p1_RmOvlp_dR0p2': 'L1_AlwaysTrue',
        'L1_DoubleJet_85_35_DoubleJet35_Mass_Min700_Mu3OQ': 'L1_AlwaysTrue',
        'L1_DoubleJet_85_35_DoubleJet35_Mass_Min800_Mu3OQ': 'L1_AlwaysTrue',
        'L1_DoubleJet_85_35_DoubleJet35_Mass_Min900_Mu3OQ': 'L1_AlwaysTrue',
        'L1_DoubleJet_70_35_DoubleJet35_Mass_Min600_ETMHF65': 'L1_AlwaysTrue',
        'L1_DoubleJet_70_35_DoubleJet35_Mass_Min700_ETMHF65': 'L1_AlwaysTrue',
        'L1_DoubleJet_70_35_DoubleJet35_Mass_Min800_ETMHF65': 'L1_AlwaysTrue',
    }

    for module in filters_by_type(process, 'HLTL1TSeed'):
        l1Seed = module.L1SeedsLogicalExpression.value()
        if any(old_seed in l1Seed for old_seed in seed_replacements):
            for old_seed, new_seed in seed_replacements.items():
                l1Seed = l1Seed.replace(old_seed, new_seed)
            module.L1SeedsLogicalExpression = cms.string(l1Seed)

    return process
"""

    configWithGTv4 = f"""from {hltLabel} import cms, process

from HLTrigger.Configuration.common import *

{customizeHLTfor2024L1TMenu}

process = customizeHLTfor2024L1TMenu(process)

process.GlobalTag.globaltag = '150X_dataRun3_HLT_forTriggerStudies_v4'
"""

    configWithGTv5 = f"""from {hltLabel} import cms, process

from HLTrigger.Configuration.common import *

{customizeHLTfor2024L1TMenu}

process = customizeHLTfor2024L1TMenu(process)

process.GlobalTag.globaltag = '150X_dataRun3_HLT_forTriggerStudies_v5'

for prod in producers_by_type(process, 'CaloTowersCreator'):
    prod.EcalRecHitThresh = True
"""

    hltCfgTypes = {
        f'{hltLabel}_GTv4': configWithGTv4,
#        f'{hltLabel}_GTv5': configWithGTv5,
    }

    print(f'Creating list of EDM input files on EOS ...')
    inputFileBlocks = []
    inputFiles = []
    for eosDir in eosDirs:
        execmd(f'eos ls {eosDir} > tmp.txt')
        inputFilesTmp = [fileName for fileName in open('tmp.txt').read().splitlines() if fileName.endswith('.root')]
        inputFiles += [f'root://eoscms.cern.ch/{eosDir}/{fileName}' for fileName in inputFilesTmp]
        os.remove('tmp.txt')
    inputFiles = sorted(list(set(inputFiles)))

    count = len(hltCfgTypes.keys())
    nRuns = len(inputFiles)
    print(f'... {nRuns} input files found')

    print(f'Downloading HLT menu ({hltMenu}) from ConfDB ...')
    execmd(hltGetCmd)

    print(f'Creating python configurations for {count} parallel jobs ', end='')
    print(f'({numThreadsPerJobs} threads and {numStreamsPerJobs} streams per job) ...')

    for hltCfgLabel in hltCfgTypes:
        with open(f'{hltCfgLabel}.py', 'w') as hltCfgFile:
            hltCfgFile.write(f'{hltCfgTypes[hltCfgLabel]}\n')

    for run_i in range(nRuns):
        if minRunNumber != None and run_i < minRunNumber:
            continue
        if maxRunNumber != None and run_i > maxRunNumber:
            continue

        runLabel = f'run{run_i:04d}'
        print(f'{runLabel} ...')

        jobCmds = []
        hltLogs = []
        fileName = inputFiles[run_i] 

        for hltCfgLabel in hltCfgTypes:
            hltLogs += [f'{hltCfgLabel}_{runLabel}.log']
            with open(f'{hltCfgLabel}.py', 'a') as hltCfgFile:
                hltCfgFile.write(f'process.hltOutputMinimal.fileName = "{hltCfgLabel}_{runLabel}.root"\n')
            jobCmds += [f'cmsRun {hltCfgLabel}.py inputFiles={fileName} &> {hltLogs[-1]}']

        pool = multiprocessing.Pool(processes=count)
        pool.map(execmd, jobCmds)

        for hltLog in hltLogs:
            execmd(f'grep -inrl fatal {hltLog}')
