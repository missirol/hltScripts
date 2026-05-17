# /eos/cms/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/FOG/HIonTest

#IDIR=/afs/cern.ch/work/r/rosma/public
IDIR=./

#cmsRun DQM/Integration/python/clients/sistrip_dqm_sourceclient-live_cfg.py \
# runInputDir="${IDIR}" runNumber=360991 runkey=hi_run scanOnce=True

cmsRun DQM/Integration/python/clients/ecal_dqm_sourceclient-live_cfg.py \
 runInputDir="${IDIR}" runNumber=360991 runkey=hi_run scanOnce=True
