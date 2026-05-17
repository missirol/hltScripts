#!/bin/bash

# cmsrel CMSSW_13_0_7
# cd CMSSW_13_0_7/src
# cmsenv

OUTFILE=hltTest368685
ACCELER=gpu-nvidia

if [ ! -f "${OUTFILE}".py ]; then

  https_proxy=http://cmsproxy.cms:3128 \
  hltGetConfiguration run:368685 \
   --data \
   --no-prescale \
   --no-output \
   --globaltag 130X_dataRun3_HLT_v2 \
   --max-events 1 \
   --paths HLT_DoubleMediumChargedIsoDisplacedPFTauHPS32_Trk1_eta2p1_v* \
   --input file:/data/user/missirol/debug_run368685/run368685_ls1009_index000027_fu-c2b02-41-01_pid1894024.root \
   > "${OUTFILE}".py

  cat <<@EOF >> "${OUTFILE}".py
del process.MessageLogger
process.load('FWCore.MessageService.MessageLogger_cfi')

process.options.numberOfThreads = 1
process.options.accelerators = ['${ACCELER}']

process.source.skipEvents = cms.untracked.uint32(64)
process.maxEvents.input = 1

#process.hltSiStripRawToClustersFacility.onDemand = False

#process.hltL2TausForPixelIsolationL1TauSeeded.cut = "pt > 30 & abs(eta) < 2.3"
#process.hltL2TauJetsL1TauSeeded.EtMin = 35

#process.hltDisplacedhltIter4PFlowPixelLessTrackingRegionsForTau.RegionPSet.zErrorVetex = 8.0
#process.hltDisplacedhltIter4PFlowPixelLessTrackingRegionsForTau.RegionPSet.maxNVertices = 1

#process.hltDisplacedhltIter4PFlowPixelLessTrackingRegionsForTau.RegionPSet = dict(
#      mode = cms.string( "VerticesFixed" ),
#      maxNRegions = cms.int32( 100 ),
#      maxNVertices = cms.int32( 10 ),
#      ptMin = cms.double( 30.0 ),
#      originRadius = cms.double( 1.0 ),
#      zErrorBeamSpot = cms.double( 24.2 ),
#      deltaEta = cms.double( 0.5 ),
#      deltaPhi = cms.double( 0.5 ),
#      precise = cms.bool( True ),
#      nSigmaZVertex = cms.double( 3.0 ),
#      zErrorVetex = cms.double( 120.0 ),
#      nSigmaZBeamSpot = cms.double( 4.0 ),
#      searchOpt = cms.bool( True )
#)
@EOF
fi

cmsRun "${OUTFILE}".py &> "${OUTFILE}".log
