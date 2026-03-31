#!/bin/bash

# Usage:
# ./run_repack.sh <input_dat_file> <runNumber>

INPUTFILE=$1
RUN=$2

if [ -z "$INPUTFILE" ] || [ -z "$RUN" ]; then
  echo "Usage: $0 <input_dat_file> <runNumber>"
  exit 1
fi

########################################
# Create repack configuration
########################################

cat <<EOF > repack_cfg.py
import FWCore.ParameterSet.Config as cms
import FWCore.ParameterSet.VarParsing as VarParsing

options = VarParsing.VarParsing('analysis')
options.parseArguments()

process = cms.Process('REPACK')

process.source = cms.Source("NewEventStreamFileReader",
    fileNames = cms.untracked.vstring(options.inputFiles)
)

process.output = cms.OutputModule('PoolOutputModule',
    fileName = cms.untracked.string(options.outputFile),
    outputCommands = cms.untracked.vstring('keep *')
)

process.options.numberOfThreads = 8
process.options.numberOfStreams = 8

process.endPath = cms.EndPath(process.output)
EOF

########################################
# Run cmsRun
########################################

cmsRun repack_cfg.py inputFiles=file:${INPUTFILE} outputFile=output.root

########################################
# Create HLT configuration
########################################

cat <<EOF > hlt_cfg.py
import FWCore.ParameterSet.Config as cms

process = cms.Process("HLTX")

process.source = cms.Source("PoolSource",
    fileNames = cms.untracked.vstring("file:output.root")
)

process.hltPSetMap = cms.EDProducer("ParameterSetBlobProducer")

process.FastMonitoringService = cms.Service("FastMonitoringService",
    tbbMonitoringMode = cms.untracked.bool(True),
    tbbConcurrencyTracker = cms.untracked.bool(True),
    sleepTime = cms.untracked.int32(1),
    fastMonIntervals = cms.untracked.uint32(2),
    filePerFwkStream = cms.untracked.bool(False),
    verbose = cms.untracked.bool(False)
)

process.EvFDaqDirector = cms.Service("EvFDaqDirector",
    baseDir = cms.untracked.string("."),
    buBaseDir = cms.untracked.string("."),
    buBaseDirsAll = cms.untracked.vstring(),
    buBaseDirsNumStreams = cms.untracked.vint32(),
    runNumber = cms.untracked.uint32(${RUN}),
    useFileBroker = cms.untracked.bool(False),
    fileBrokerHostFromCfg = cms.untracked.bool(True),
    fileBrokerHost = cms.untracked.string("InValid"),
    fileBrokerPort = cms.untracked.string("8080"),
    fileBrokerKeepAlive = cms.untracked.bool(True),
    fileBrokerUseLocalLock = cms.untracked.bool(True),
    fuLockPollInterval = cms.untracked.uint32(2000),
    outputAdler32Recheck = cms.untracked.bool(False),
    directorIsBU = cms.untracked.bool(False),
    hltSourceDirectory = cms.untracked.string(""),
    mergingPset = cms.untracked.string("")
)

process.hltOutputDQM = cms.OutputModule( "GlobalEvFOutputModule",
    use_compression = cms.untracked.bool( True ),
    compression_algorithm = cms.untracked.string( "ZSTD" ),
    compression_level = cms.untracked.int32( 3 ),
    lumiSection_interval = cms.untracked.int32( 0 ),
    SelectEvents = cms.untracked.PSet(  SelectEvents = cms.vstring( '*' ) ),
    outputCommands = cms.untracked.vstring( 'drop *',     
      'keep *_*_*_HLT' ),
    psetMap = cms.untracked.InputTag( "hltPSetMap" )
)

process.HLTriggerFirstPath = cms.Path(process.hltPSetMap)
process.DQMOutput = cms.EndPath( process.hltOutputDQM )
EOF

########################################
# Create the directory and run the "HLT-like" process
########################################
RUN_DIR="run${RUN}"
mkdir $RUN_DIR
cmsRun hlt_cfg.py

########################################
# Detect stream, pid, lumi automatically
########################################
DATFILE=$(ls ${RUN_DIR}/run${RUN}_ls*_stream*_pid*.dat | head -n1)

if [ -z "$DATFILE" ]; then
  echo "No dat file found in ${RUN_DIR}"
  exit 1
fi

FILENAME=$(basename "$DATFILE")

# Extract components
STREAM=$(echo "$FILENAME" | sed -E 's/.*_stream([^_]+)_pid.*/\1/')
PID=$(echo "$FILENAME" | sed -E 's/.*_pid([0-9]+).*/\1/')
LUMI=$(echo "$FILENAME" | sed -E 's/run[0-9]+_ls([0-9]+)_stream.*/\1/')

echo "Detected:"
echo "Stream = $STREAM"
echo "PID    = $PID"
echo "Lumi   = $LUMI"

INI_FILE="${RUN_DIR}/run${RUN}_ls0000_stream${STREAM}_pid${PID}.ini"
DAT_FILE="${RUN_DIR}/run${RUN}_ls${LUMI}_stream${STREAM}_pid${PID}.dat"

OUTPUT_FILE="${RUN_DIR}/run${RUN}_ls${LUMI}_stream${STREAM}_pid${PID}.dat"

echo "Concatenating:"
echo "$INI_FILE"
echo "$DAT_FILE"

cat "$INI_FILE" "$DAT_FILE" > "${OUTPUT_FILE}.tmp"
mv "${OUTPUT_FILE}.tmp" "$OUTPUT_FILE"

########################################
# emulate merging
########################################
echo "Fixing duplicated zeros in JSON data arrays"

for jsn in ${RUN_DIR}/*.jsn; do
  tmp="${jsn}.tmp"

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
  ' "$jsn" > "$tmp"

  mv "$tmp" "$jsn"
done

########################################
# Cleanup directory
########################################

echo "Cleaning ${RUN_DIR} (keeping only .dat and .jsn)"

find "$RUN_DIR" -type f ! -name "*.dat" ! -name "*.jsn" -delete

# Remove all subdirectories
find "$RUN_DIR" -mindepth 1 -type d -exec rm -rf {} +
