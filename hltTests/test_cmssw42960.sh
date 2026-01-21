#!/bin/bash

# defaults
showHelpMsg=false
runNumKeyword=-1
numThreadsDefault=32
numThreads="${numThreadsDefault}"
numStreamsDefault=0
numStreams="${numStreamsDefault}"
errDirPathDefault=/store/error_stream
errDirPath="${errDirPathDefault}"
outDirPathDefault=tmp
outDirPath="${outDirPathDefault}"
outDirOverWriteDefault=false
outDirOverWrite="${outDirOverWriteDefault}"
extraFilePatternDefault=""
extraFilePattern="${extraFilePatternDefault}"
noCmsRunDefault=false
noCmsRun="${noCmsRunDefault}"

# help message
usage() {
  cat <<@EOF
Description:
  This script can be used to run the HLT menu of a given run on error-stream files in FEDRawData (FRD) format.
  One cmsRun job per file is executed. The log files of all jobs are saved in an output directory.
  If a given job fails, the name of the corresponding log file is added to a file named "failed.txt" in the output directory.
  For all the files of a given run, the script uses the same HLT menu as used online during that run.

Example:
  The example below runs on all the files matching "/store/error_stream/run3676*/*fu-c2b04-32-01*.raw".
  Each cmsRun job uses 32 threads and 24 CMSSW streams. The results are saved in an directory named "tmp".
  If the output directory already exists, it will be overwritten, since "-w" is specified.

  > ./rerun_hlt_on_error_stream.sh -r 3676 -t 32 -s 24 -i /store/error_stream -f fu-c2b04-32-01 -o tmp -w

Options:
  -h, --help          Show this help message

  -r, --runNumber     Run number (a wildcard is appended: for example,
                      if "-r 123" is used, all runs matching "123*" will be considered)

  -t, --threads       Number of threads                     [Optional] [Default: ${numThreadsDefault}]

  -s, --streams       Number of CMSSW streams               [Optional] [Default: ${numStreamsDefault}]

  -i, --input-dir     Path to error-stream directory        [Optional] [Default: ${errDirPathDefault}]
                      containing one sub-folder per run

  -o, --output-dir    Path to output directory              [Optional] [Default: ${outDirPathDefault}]

  -w, --overwrite     Overwrite output directory
                      (if it already exists)                [Optional] [Default: ${outDirOverWriteDefault}]

  -f, --file-pattern  String to be used to restrict to
                      a subset of input files               [Optional] [Default: ${extraFilePatternDefault}]

  -n, --no-cmsRun     Do not run cmsRun job(s)              [Optional] [Default: ${noCmsRunDefault}]

  If optional arguments are not specified, the corresponding default values will be used.

@EOF
}

# command-line interface
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) showHelpMsg=true; shift;;
    -r|--runNumber) runNumKeyword=$2; shift; shift;;
    -t|--threads) numThreads=$2; shift; shift;;
    -s|--streams) numStreams=$2; shift; shift;;
    -i|--input-dir) errDirPath=$2; shift; shift;;
    -o|--output-dir) outDirPath=$2; shift; shift;;
    -w|--overwrite) outDirOverWrite=true; shift;;
    -f|--file-pattern) extraFilePattern=$2; shift; shift;;
    -n|--no-cmsRun) noCmsRun=true; shift;;
    *) shift;;
  esac
done

# print help message
if [ "${showHelpMsg}" == true ]; then
  usage
  exit 0
fi

posNumRegex='^[0-9]+$'
if ! [[ "${runNumKeyword}" =~ ${posNumRegex} ]] ; then
  printf "\n\033[31m\033[1m%s\033[0m%s\n\n" ">> ERROR" " -- invalid run number (must be a positive integer without sign) [-r]: ${runNumKeyword}"
  exit 1
elif [ "${runNumKeyword}" -le 0 ]; then
  printf "\n\033[31m\033[1m%s\033[0m%s\n\n" ">> ERROR" " -- invalid run number (must be a number higher than zero) [-r]: ${runNumKeyword}"
  exit 1
fi

if ! [[ "${numThreads}" =~ ${posNumRegex} ]] ; then
  printf "\n\033[31m\033[1m%s\033[0m%s\n\n" ">> ERROR" " -- invalid number of threads per job (must be a positive integer without sign) [-t]: ${numThreads}"
  exit 1
elif [ "${numThreads}" -le 0 ]; then
  printf "\n\033[31m\033[1m%s\033[0m%s\n\n" ">> ERROR" " -- invalid number of threads per job (must be a number higher than zero) [-t]: ${numThreads}"
  exit 1
fi

if ! [[ "${numStreams}" =~ ${posNumRegex} ]] ; then
  printf "\n\033[31m\033[1m%s\033[0m%s\n\n" ">> ERROR" " -- invalid number of CMSSW streams per job (must be a positive integer without sign) [-s]: ${numStreams}"
  exit 1
fi

if [ ! -d "${errDirPath}" ]; then
  printf "\n\033[31m\033[1m%s\033[0m%s\n\n" ">> ERROR" " -- target input directory does not exist [-i]: ${errDirPath}"
  exit 1
fi

if [ -z "${CMSSW_BASE}" ]; then
  printf "\n\033[31m\033[1m%s\033[0m%s" ">> ERROR" " -- environment variable CMSSW_BASE not found"
  printf "%s\n" ": it is necessary to first set up the CMSSW environment"
  printf "%s\n\n" "            (for example via \"source setup.sh -r CMSSW_X_Y_Z\")"
  exit 1
fi

errDirAbsPath=$(readlink -e "${errDirPath}")
runDirPrePath="${errDirAbsPath}"/run"${runNumKeyword}"

if [ $(ls -d "${runDirPrePath}"* 2> /dev/null | wc -l) -eq 0 ]; then
  printf "\n\033[31m\033[1m%s\033[0m%s\n\n" ">> ERROR" " -- no input directories found: ${runDirPrePath}*"
  exit 1
fi

[ "${outDirOverWrite}" != true ] || (rm -rf "${outDirPath}")

if [ -d "${outDirPath}" ]; then
  printf "\n\033[31m\033[1m%s\033[0m%s\n\n" ">> ERROR" " -- target output directory already exists [-o]: ${outDirPath}"
  exit 1
fi

mkdir -p "${outDirPath}"
cd "${outDirPath}"

for dirPath in $(ls -d "${runDirPrePath}"*); do
  runNumber="${dirPath: -6}"
  echo "--------------------------------------------------"
  echo " run: ${runNumber}"
  echo "--------------------------------------------------"
  hltGetCmd="hltConfigFromDB --runNumber ${runNumber}"
  echo "${hltGetCmd} ..."
  hltCfg=run"${runNumber}"_cfg.py
  ${hltGetCmd} > "${hltCfg}"
  hltCfg=$(readlink -e "${hltCfg}")
  cat <<EOF >> "${hltCfg}"
import sys
if len(sys.argv) < 3:
    raise RuntimeError("one command-line argument required: path to file in FEDRawData (FRD) format")

process.source.fileListMode = True
process.source.fileNames = [sys.argv[2]]

process.options.numberOfThreads = ${numThreads}
process.options.numberOfStreams = ${numStreams}

del process.PrescaleService

del process.MessageLogger
process.load('FWCore.MessageService.MessageLogger_cfi')

process.EvFDaqDirector.buBaseDir = "${errDirAbsPath}"
process.EvFDaqDirector.runNumber = ${runNumber}

process.hltDQMFileSaverPB.runNumber = ${runNumber}

if hasattr(process, "hltOnlineBeamSpotESProducer"):
    process.hltOnlineBeamSpotESProducer.timeThreshold = int(1e6)

# remove paths containing OutputModules
streamPaths = [pathName for pathName in process.finalpaths_()]
for foo in streamPaths:
    process.__delattr__(foo)
EOF
  # array of non-empty FRD files
  frdFiles=($(cd "${dirPath}" ; find -maxdepth 1 -size +0 | grep .raw))
  for frdFile in "${frdFiles[@]}"; do
    frdFileBasename=$(basename "${frdFile}")
    if [[ "${frdFileBasename}" != *"${extraFilePattern}"* ]]; then
      continue
    fi
    jobTag="${frdFileBasename::-4}"
    hltLog="${jobTag}".log
    frdFileAbsPath=$(readlink -e "${dirPath}"/"${frdFileBasename}")
    echo -e "\n${jobTag} ..."
    echo -e "# cmsRun ${hltCfg} ${frdFileAbsPath}\n" > "${hltLog}"
    if [ "${noCmsRun}" != true ]; then
      rm -rf run"${runNumber}" && mkdir -p run"${runNumber}"
      cmsRun "${hltCfg}" "${frdFileAbsPath}" &>> "${hltLog}"
      exitCode=$?
      [ ${exitCode} -eq 0 ] || echo "${hltLog}" >> failed.txt
      echo "${jobTag} ... done (exit code: ${exitCode})"
    fi
  done
  rm -rf run"${runNumber}"
  unset frdFile frdFiles
  unset runNumber hltCfg
done
unset dirPath
