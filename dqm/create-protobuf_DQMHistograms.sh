#!/bin/bash -ex
RUNNUMBER=402360 # 2026 EphemeralHLTPhysics
LUMISECTION=193

# cmsrel CMSSW_16_0_5_patch1
# cd CMSSW_16_1_X_2026-01-21-2300/src/
# cmsenv

INPUTFILE="root://eoscms.cern.ch//store/data/Run2026B/EphemeralHLTPhysics0/RAW/v1/000/402/360/00000/aa48b021-759e-4592-86e5-75eee46b88fc.root"
rm -rf run${RUNNUMBER}*

# run on 500 events of LS, with 500 events per input file
convertToRaw -f 500 -l 500 -r ${RUNNUMBER}:${LUMISECTION} -o . -- "${INPUTFILE}"

tmpfile=tmpFile.py
hltConfigFromDB --configName /online/collisions/2026/2e34/v1.1/HLT/V2 > "${tmpfile}"
cat <<@EOF >> "${tmpfile}"
process.load("run${RUNNUMBER}_cff")

# to run without any HLT prescales
del process.PrescaleService
del process.MessageLogger
process.load('FWCore.MessageLogger.MessageLogger_cfi')

process.options.numberOfThreads = 32
process.options.numberOfStreams = 32

process.options.wantSummary = True
process.GlobalTag.globaltag = cms.string( "160X_dataRun3_HLT_v1" )
# # to run using the same HLT prescales as used online in LS 1000
# process.PrescaleService.forceDefault = True

# customization for the menu

## just output the GPU vs CPU output
streamPaths = [foo for foo in process.endpaths_() if foo.endswith('Output')]
for foo in streamPaths:
    process.__delattr__(foo)
@EOF
edmConfigDump "${tmpfile}" > hlt.py

cmsRun hlt.py &> hlt.log

bash -c 'echo $$ > cmsrun.pid; exec cmsRun hlt.py &> hlt.log'
job_pid=$(cat cmsrun.pid)
echo "cmsRun is running with PID: $job_pid"

# remove input files to save space
# rm -f run${RUNNUMBER}/run${RUNNUMBER}_ls0*_index*.*

# # prepare the files by concatenating the .ini and .dat files
mkdir -p prepared

fastHadd add -o prepared/run${RUNNUMBER}_ls0${LUMISECTION}_streamDQMHistograms_pid${job_pid}.pb run${RUNNUMBER}/run*_ls*_streamDQMHistograms_pid*.pb
cp run${RUNNUMBER}/run${RUNNUMBER}_ls0${LUMISECTION}_streamDQMHistograms_pid${job_pid}.jsn prepared/run${RUNNUMBER}_ls0${LUMISECTION}_streamDQMHistograms_pid${job_pid}_prep.jsn

# now remove the extra 0
input="prepared/run${RUNNUMBER}_ls0${LUMISECTION}_streamDQMHistograms_pid${job_pid}_prep.jsn"
output="prepared/run${RUNNUMBER}_ls0${LUMISECTION}_streamDQMHistograms_pid${job_pid}.jsn"

jq '
  .data as $d |
  .data = (
    reduce range(0; $d|length) as $i ([];
      if ($i > 0 and .[-1] == "0" and $d[$i] == "0")
      then .
      else . + [$d[$i]]
      end
    )
  )
' "$input" > "$output"

rm -fr $input
rm -fr run${RUNNUMBER}* hlt.* cmsrun.pid dump.py __pycache__
mv prepared run${RUNNUMBER}
