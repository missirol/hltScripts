#!/usr/bin/env python3
import os
import sys
import math
import multiprocessing

def execmd(cmd):
    return os.system(cmd)

if __name__ == '__main__':

    ###
    ### parameters
    ###
    hltLabel1 = sys.argv[1]

    maxNumRuns = int(sys.argv[2])
    numEventsPerJob = -1

    numThreadsPerJobs = 32
    numStreamsPerJobs = 20

    hltMenu = 'adg:/cdaq/test/missirol/dev/CMSSW_14_1_0/CMSHLT_3387/Test01/HLT/V4'

    inputType = 'data'

    runs = [609,612,614,628,631,658,659,665,697,703,739,746,754,790,823]
    eosDirs = [f'/eos/cms/store/hidata/HIRun2023A/HIEphemeralHLTPhysics/RAW/v1/000/375/{foo}/00000' for foo in runs]
    globalTag = '141X_dataRun3_HLT_v1'

    hltGetCmd = f"""
https_proxy=http://cmsproxy.cms:3128/ \
hltGetConfiguration {hltMenu} \
  --globaltag {globalTag} \
  --{inputType} \
  --no-prescale \
  --no-output \
  --max-events {numEventsPerJob} \
  --eras Run3_2024 --l1-emulator uGT --l1 L1Menu_CollisionsHeavyIons2024_v1_0_5_xml \
  > {hltLabel1}.py && \
cat <<@EOF >> {hltLabel1}.py
process.options.numberOfThreads = {numThreadsPerJobs}
process.options.numberOfStreams = {numStreamsPerJobs}
process.options.wantSummary = True

for foo in ['HLTAnalyzerEndpath', 'MessageLogger']:
    if hasattr(process, foo):
        process.__delattr__(foo)

process.load('FWCore.MessageLogger.MessageLogger_cfi')

process.FastTimerService.dqmTimeRange = 90000
process.FastTimerService.enableDQMbyPath = True
process.FastTimerService.dqmPathTimeRange = 90000
process.FastTimerService.dqmPathTimeResolution = 1000
process.FastTimerService.dqmPathMemoryRange = 1000000
process.FastTimerService.dqmPathMemoryResolution = 25000
process.FastTimerService.enableDQMbyModule = True
process.FastTimerService.dqmModuleTimeRange = 10000
process.FastTimerService.dqmModuleTimeResolution = 500
process.FastTimerService.dqmModuleMemoryRange = 100000
process.FastTimerService.dqmModuleMemoryResolution = 2500
@EOF
"""

    print(f'Creating list of EDM input files on EOS ...')
    inputFileBlocks = []
    inputFiles = []
    for eosDir in eosDirs:
        execmd(f'eos ls {eosDir} > tmp.txt')
        inputFilesTmp = [fileName for fileName in open('tmp.txt').read().splitlines() if fileName.endswith('.root')]
        inputFiles += [f'root://eoscms.cern.ch/{eosDir}/{fileName}' for fileName in inputFilesTmp]
        os.remove('tmp.txt')
    inputFiles = sorted(list(set(inputFiles)))

    print(f'.. {len(inputFiles)} EDM files found on EOS.')

    count = multiprocessing.cpu_count() // numThreadsPerJobs
    nRuns = math.ceil(len(inputFiles) / count)

    for run_i in range(nRuns):
        inputFileBlocks.append(inputFiles[count*run_i:count*(run_i+1)])

    print(f'Downloading HLT menu ({hltMenu}) from ConfDB ...')
    execmd(hltGetCmd)

    print(f'Creating python configurations for {count} parallel jobs ', end='')
    print(f'({numThreadsPerJobs} threads and {numStreamsPerJobs} streams per job) ...')

    for run_i in range(nRuns):
        if maxNumRuns >= 0 and run_i >= maxNumRuns:
            continue

        runLabel = f'run{run_i:03d}'
        print(f'{runLabel} ...')

        jobCmds = []
        hltLogs = []
        for job_i,fileName in enumerate(inputFileBlocks[run_i]):
            hltLabel2 = f'{hltLabel1}_{runLabel}_job{job_i}'
            with open(f'{hltLabel2}.py', 'w') as ofile:
                ofile_str = f'from {hltLabel1} import cms,process\n'
                ofile_str += f'process.source.fileNames = ["{fileName}"]\n'
                ofile_str += f'process.dqmOutput.fileName = "{hltLabel2}_DQMIO.root"\n'
                ofile.write(ofile_str)
            hltLogs += [f'{hltLabel2}.log']
            jobCmds += [f'cmsRun {hltLabel2}.py &> {hltLabel2}.log']

        pool = multiprocessing.Pool(processes=count)
        pool.map(execmd, jobCmds)

        for hltLog in hltLogs:
            execmd(f'grep -inrl fatal {hltLog}')
