#!/bin/bash -ex

# cmsrel CMSSW_13_2_0
# cd CMSSW_13_2_0/src
# cmsenv
# git cms-addpkg HLTrigger/Tools
# git checkout -b test_streamersOfHIon2022_in_132X
# git cherry-pick a2e95c82ae5a8843d1b899be3cdc6e118e1e0618
# scram b

# run 362321, LSs 231-232
INPUTFILE=root://eoscms.cern.ch//eos/cms/store/user/cmsbuild//store/hidata/HIRun2022A/HITestRaw0/RAW/v1/000/362/321/00000/f467ee64-fc64-47a6-9d8a-7ca73ebca2bd.root

HLTMENU=/users/missirol/test/dev/CMSSW_13_2_0/CMSHLT_2884/Test01/HLT/V3

rm -rf run362321*

# run on 5000 events of LS 231, with 500 events per input file
convertToRaw -f 500 -l 5000 -r 362321:231 -s rawDataRepacker -o . -- "${INPUTFILE}"

tmpfile=$(mktemp)
hltConfigFromDB --configName "${HLTMENU}" > "${tmpfile}"
cat <<@EOF >> "${tmpfile}"
process.load('run362321_cff')
process.hltOnlineBeamSpotESProducer.timeThreshold = int(1e6)

# to run without any HLT prescales
del process.PrescaleService

# # to run using the same HLT prescales as used online in LS 231
# process.PrescaleService.forceDefault = True
@EOF
edmConfigDump "${tmpfile}" > hlt.py

cmsRun hlt.py &> hlt.log

# # remove input files to save space
# rm -f run362321/run362321_ls0*_index*.*
