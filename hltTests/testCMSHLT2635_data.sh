#!/bin/bash

hltGetConfiguration \
  /users/missirol/test/dev/CMSSW_13_0_0/CMSHLT_2635/Test02/HLT/V1 \
  --setup /dev/CMSSW_13_0_0/GRun \
  --input \
/store/data/Run2022F/ParkingDoubleElectronLowMass3/RAW/v1/000/361/054/00000/f53526b4-7c53-466e-8a06-d5a9c2719663.root,\
/store/data/Run2022F/ParkingDoubleElectronLowMass3/RAW/v1/000/361/054/00000/06130987-fa47-4d53-81a5-bd37d5aa04ca.root,\
/store/data/Run2022F/ParkingDoubleElectronLowMass3/RAW/v1/000/361/054/00000/ce75f408-3d2d-42e2-8b46-e9748b160819.root,\
/store/data/Run2022F/ParkingDoubleElectronLowMass3/RAW/v1/000/361/054/00000/9e3fa903-3db6-4b12-9047-0826850fa650.root,\
/store/data/Run2022F/ParkingDoubleElectronLowMass3/RAW/v1/000/361/054/00000/0802d2ae-0970-4655-b381-8c67eb6cde47.root \
  --data \
  --max-events 5000 \
  --globaltag 126X_dataRun3_HLT_v1 \
  --no-prescale \
  --output minimal \
  --eras Run3 \
  --l1-emulator Full \
  --l1 L1Menu_Collisions2022_v1_4_0-d1_xml \
  > hlt_testEG_Data.py

cat <<@EOF >> hlt_testEG_Data.py
process.options.numberOfThreads = 1
@EOF

cmsRun hlt_testEG_Data.py &> hlt_testEG_Data.log
