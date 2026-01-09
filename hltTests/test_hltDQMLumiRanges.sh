#!/bin/bash -ex

INPUTFILE=file:/eos/cms/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STORM/RAW/Run2022G_EphemeralHLTPhysics0_run362616/82ed6819-9c96-49e1-a5ed-b5edc1a90108.root

RUNNUM=362616

rm -rf run"${RUNNUM}"* upload
convertToRaw -f 500 -l 500 -r "${RUNNUM}":209 -o . -- "${INPUTFILE}"

tmpfile=$(mktemp)
hltConfigFromDB --runNumber 367406 > "${tmpfile}"
cat <<@EOF >> "${tmpfile}"
process.load("run${RUNNUM}_cff")
process.hltLumiMonitor.histoPSet.lumiPSet.xmax = 30000
process.hltLumiMonitor.histoPSet.lumiPSet.nbins = 6000
process.hltOnlineBeamSpotESProducer.timeThreshold = int(1e6)
del process.PrescaleService
removeObjs = [pathName for pathName in process.paths_() if not pathName.endswith('Path')] + [pathName for pathName in process.finalpaths_()]
for foo in removeObjs:
    process.__delattr__(foo)
@EOF
edmConfigDump "${tmpfile}" > hlt.py

cmsRun hlt.py &> hlt.log

cmsRun "${CMSSW_BASE}"/src/DQM/Integration/python/clients/hlt_dqm_clientPB-live_cfg.py \
  runInputDir=. runNumber="${RUNNUM}" runkey=pp_run scanOnce=True \
  datafnPosition=4
