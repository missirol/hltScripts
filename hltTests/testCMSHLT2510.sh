#!/bin/bash -ex

# default configuration
SHOW_HELP=false
OUTPUT_DIR=tmp16_2_v2
RUN_NUMBER=361579
BENCHMARK_EXE=
BENCHMARK_EVENTS=10300
BENCHMARK_JOBS=4
BENCHMARK_THREADS=16

# help message
usage() {
  cat <<@EOF
Usage:
  This script produces configuration files, and runs throughput estimates,
  for offloading of PFRecHits and PFClustering to GPU.
  Throughput estimates are done with the executable patatrack-scripts/benchmark.
Options:
  -h, --help            Show this help message
  -o, --output-dir      Path to output directory                          [Default: ${OUTPUT_DIR}]
  -r, --run             Number of run to use for input data               [Default: ${RUN_NUMBER}]
  -b, --benchmark-exe   Path to patatrack-scripts/benchmark executable    [Default: ${BENCHMARK_EXE}]
  -e, --events          Throughput estimates: number of events            [Default: ${BENCHMARK_EVENTS}]
  -j, --jobs            Throughput estimates: number of jobs              [Default: ${BENCHMARK_JOBS}]
  -t, --threads         Throughput estimates: number of threads per job   [Default: ${BENCHMARK_THREADS}]
@EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) SHOW_HELP=true; shift;;
    -o|--output-dir) OUTPUT_DIR=$2; shift; shift;;
    -b|--benchmark-exe) BENCHMARK_EXE=$2; shift; shift;;
    -e|--events) BENCHMARK_EVENTS=$2; shift; shift;;
    -j|--jobs) BENCHMARK_JOBS=$2; shift; shift;;
    -t|--threads) BENCHMARK_THREADS=$2; shift; shift;;
    *) shift;;
  esac
done

# print help message and exit
if [ "${SHOW_HELP}" = true ]; then
  usage
  exit 0
fi

# exit if output directory already exists
if [ -d "${OUTPUT_DIR}" ]; then
  printf "\n%s\n\n" "ERROR: target output directory already exists: ${OUTPUT_DIR}"
  exit 1
fi

# convert BENCHMARK_EXE to absolute path, if needed
[ ! -f "${BENCHMARK_EXE}" ] || BENCHMARK_EXE=$(readlink -e "${BENCHMARK_EXE}")

# create output directory and move to it
mkdir -p "${OUTPUT_DIR}"
cd "${OUTPUT_DIR}"

###
### build cmsDriver command with options common to all wfs
###
HLTCONFCMD="hltConfigFromDB --runNumber ${RUN_NUMBER}"

# copy cff with source holding Run2022 data files in .raw format
cp /gpu_data/store/data/Run2022F/HLTPhysics/FED/v1/run"${RUN_NUMBER}"_cff.py .

###
### custom.py: customisations common to all configuration files
###
cat <<@EOF > custom.py

# force prescale column
process.PrescaleService.lvl1DefaultLabel = "2p0E34+ZeroBias+HLTPhysics"
process.PrescaleService.forceDefault = True

# write the timing summary
process.FastTimerService.jsonFileName = "resources.json"
process.FastTimerService.writeJSONSummary = True

# set the process parameters
process.options.numberOfConcurrentLuminosityBlocks = 2      # default: 2
process.options.numberOfStreams = 32                        # default: 32
process.options.numberOfThreads = 32                        # default: 32
process.options.wantSummary = False

process.load("run${RUN_NUMBER}_cff")
@EOF

###
### process.MessageLogger.cerr.enableStatistics = True
###
https_proxy=http://cmsproxy.cms:3128/ ${HLTCONFCMD} > .tmp.py
cat custom.py >> .tmp.py
cat <<@EOF >> .tmp.py
process.MessageLogger.cerr.enableStatistics = cms.untracked.bool( True )
@EOF
edmConfigDump .tmp.py -o hlt_msgLoggerStatTrue_cfg.py

###
### process.MessageLogger.cerr.enableStatistics = False
###
https_proxy=http://cmsproxy.cms:3128/ ${HLTCONFCMD} > .tmp.py
cat custom.py >> .tmp.py
cat <<@EOF >> .tmp.py
process.MessageLogger.cerr.enableStatistics = cms.untracked.bool( False )
@EOF
edmConfigDump .tmp.py -o hlt_msgLoggerStatFalse_cfg.py

###
### benchmarking
###

# run throughput estimates if patatrack-scripts/benchmark is available
if [ -f "${BENCHMARK_EXE}" ]; then
  for cfgname in hlt_msgLoggerStatTrue hlt_msgLoggerStatFalse; do
    echo "Events  : ${BENCHMARK_EVENTS}"  >  "${cfgname}"_benchmark.log
    echo "Jobs    : ${BENCHMARK_JOBS}"    >> "${cfgname}"_benchmark.log
    echo "Threads : ${BENCHMARK_THREADS}" >> "${cfgname}"_benchmark.log
    echo "Streams : ${BENCHMARK_THREADS}" >> "${cfgname}"_benchmark.log
    ${BENCHMARK_EXE} "${cfgname}"_cfg.py  --log "${cfgname}"_logs \
      -e "${BENCHMARK_EVENTS}" -j "${BENCHMARK_JOBS}" -t "${BENCHMARK_THREADS}" -s "${BENCHMARK_THREADS}" \
      2>&1 | tee -a "${cfgname}"_benchmark.log
  done
  unset cfgname
else
  printf "\n%s\n\n" ">>> WARNING: throughput estimates not done, path to patatrack-scripts/benchmark is invalid: ${BENCHMARK_EXE}"
fi

rm -rf __pycache__ .tmp.py
cd ..
