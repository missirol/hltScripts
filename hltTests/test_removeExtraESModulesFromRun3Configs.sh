#!/bin/bash -ex

cmsDriver.py tmp \
 --no_output --no_exec -n 10 \
 --filein /store/data/Run2025D/EphemeralHLTPhysics0/RAW/v1/000/394/959/00000/02ab3d20-66ba-4372-8f06-5d09e0848408.root \
 --era Run3_2025 --data --conditions 160X_dataRun3_HLT_v1 --geometry DB:Extended \
 -s L1REPACK:FullSimTP --python_filename tmp.py

cat <<@EOF >> tmp.py
from FWCore.Modules.EventSetupRecordDataGetter import EventSetupRecordDataGetter
process.eventSetupRecordDataGetter = EventSetupRecordDataGetter()
process.Path_esRcdDataGetter = cms.Path(process.eventSetupRecordDataGetter)
process.schedule.append(process.Path_esRcdDataGetter)

del process.RPCConeBuilder
del process.rpcconesrc
del process.l1tHGCalTriggerGeometryESProducer
del process.CastorDbProducer
del process.CastorGeometryFromDBEP
del process.muonGeometryConstants
del process.EcalLaserCorrectionServiceMC
@EOF

edmConfigDump tmp.py > tmp_dump1.py
edmConfigDump --prune tmp.py > tmp_dump2.py

cmsRun tmp_dump2.py 2>&1 | tee tmp_dump2.log
