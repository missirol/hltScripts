#!/bin/bash

cmsDriver.py foo \
 -s DIGI:pdigi_valid,L1TrackTrigger \
 --conditions auto:phase2_realistic_T33 \
 --datatier GEN-SIM-DIGI-RAW -n 10 --eventcontent FEVTDEBUGHLT \
 --geometry DD4hepExtendedRun4D110 --era Phase2C17I13M9 --procModifiers dd4hep \
 --filein file:step1.root \
 --fileout tmp.root \
 --no_exec --python_filename test.py

cat <<@EOF >> test.py

process.FEVTDEBUGHLToutput.outputCommands = [
  'drop *',
  'keep *_l1tTTTracksFromTrackletEmulation_*_*',
  'keep *_ProducerDTC_StubAccepted_*',
  'keep *_TTClusterAssociatorFromPixelDigis_ClusterAccepted_*',
  'keep *_TTStubAssociatorFromPixelDigis_StubAccepted_*',
  'keep *_TTStubsFromPhase2TrackerDigis_StubAccepted_*',
]
@EOF

for nnn in {00..19}; do
  cp test.py test"${nnn}".py

  cat <<@EOF >> test"${nnn}".py

process.FEVTDEBUGHLToutput.fileName = 'test${nnn}.root'
@EOF

  cmsRun test"${nnn}".py &> test"${nnn}".log
done
unset nnn
