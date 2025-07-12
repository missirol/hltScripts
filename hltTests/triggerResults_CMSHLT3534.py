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
    minRunNumber = 0
    maxRunNumber = 99
    numEventsPerJob = -1

    numThreadsPerJobs = 32
    numStreamsPerJobs = 24

    eosDirs = [f'/eos/cms/store/data/Run2025C/HLTPhysics/RAW/v1/000/393/461/00000/']

    hltMenu1 = '/users/missirol/test/dev/CMSSW_15_0_0/CMSHLT_3534/Test11/GRun/V1'
    hltMenu2 = '/users/missirol/test/dev/CMSSW_15_0_0/CMSHLT_3534/Test11/GRun/V5'

    hltLabel1 = sys.argv[1]+'_ref'
    hltLabel2 = sys.argv[1]+'_tar'

    def hltGetCmd(hltMenu, hltLabel):
        return f"""
https_proxy=http://cmsproxy.cms:3128/ \
hltGetConfiguration {hltMenu} \
  --process HLTX \
  --globaltag 150X_dataRun3_HLT_v1 \
  --data \
  --prescale "2p0E34" \
  --output minimal \
  --max-events {numEventsPerJob} \
  > {hltLabel}.py && \
cat <<@EOF >> {hltLabel}.py
process.options.numberOfThreads = {numThreadsPerJobs}
process.options.numberOfStreams = {numStreamsPerJobs}
process.options.wantSummary = False

for foo in ['HLTAnalyzerEndpath', 'dqmOutput']: #, 'MessageLogger']:
    if hasattr(process, foo):
        process.__delattr__(foo)

#process.load('FWCore.MessageLogger.MessageLogger_cfi')

process.hltOutputMinimal.outputCommands = [
    'drop *',
    'keep edmTriggerResults_*_*_HLTX',
]

process.options.accelerators = ['cpu']
@EOF
"""

    hltGetCmd1 = hltGetCmd(hltMenu1, hltLabel1)
    hltGetCmd2 = hltGetCmd(hltMenu2, hltLabel2)

    config_ref = f"from {hltLabel1} import cms, process"

    config_tar = f"from {hltLabel2} import cms, process"

    hltCfgTypes = {
        f'{hltLabel1}_V1': config_ref,
        f'{hltLabel2}_V5': config_tar,
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

    print(f'Downloading HLT menu ({hltMenu1}) from ConfDB ...')
    execmd(hltGetCmd1)

    print(f'Downloading HLT menu ({hltMenu2}) from ConfDB ...')
    execmd(hltGetCmd2)

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
        fileName = inputFiles[run_i]

        for hltCfgLabel in hltCfgTypes:
            hltLog = f'{hltCfgLabel}_{runLabel}.log'
            with open(f'{hltCfgLabel}.py', 'a') as hltCfgFile:
                hltCfgFile.write(f'process.hltOutputMinimal.fileName = "{hltCfgLabel}_{runLabel}.root"\n')
            jobCmds += [f'cmsRun {hltCfgLabel}.py inputFiles={fileName} &> {hltLog}']

        pool = multiprocessing.Pool(processes=count)
        pool.map(execmd, jobCmds)
