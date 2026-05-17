#!/bin/bash

hltGetConfiguration /dev/CMSSW_14_0_0/GRun/V151 \
  --paths AlCa_PFJet*_v*,HLT_DoubleL2Mu23NoVtx_2Cha_CosmicSeed_v* \
  > hlt.py

cat <<EOF >> hlt.py
process.hltMuonRPCDigis = cms.EDProducer("RPCDigiMerger",
    InputLabel = cms.InputTag("rawDataCollector"),
    bxMaxCPPF = cms.int32(2),
    bxMaxOMTF = cms.int32(4),
    bxMaxTwinMux = cms.int32(2),
    bxMinCPPF = cms.int32(-2),
    bxMinOMTF = cms.int32(-3),
    bxMinTwinMux = cms.int32(-2),
    inputTagCPPFDigis = cms.InputTag("hltMuonRPCDigisCPPF"),
    inputTagOMTFDigis = cms.InputTag("hltOmtfDigis"),
    inputTagSimRPCDigis = cms.InputTag(""),
    inputTagTwinMuxDigis = cms.InputTag("hltMuonRPCDigisTwinMux"),
    mightGet = cms.optional.untracked.vstring
)

process.hltMuonRPCDigisCPPF = cms.EDProducer("RPCAMCRawToDigi",
    RPCAMCUnpacker = cms.string('RPCCPPFUnpacker'),
    RPCAMCUnpackerSettings = cms.PSet(
        bxMax = cms.int32(2),
        bxMin = cms.int32(-2),
        cppfDaqDelay = cms.int32(2),
        fillAMCCounters = cms.bool(True)
    ),
    calculateCRC = cms.bool(True),
    fillCounters = cms.bool(True),
    inputTag = cms.InputTag("rawDataCollector"),
)

process.hltOmtfDigis = cms.EDProducer("OmtfUnpacker",
    inputLabel = cms.InputTag("rawDataCollector"),
    skipRpc = cms.bool(False)
)

process.hltMuonRPCDigisTwinMux = cms.EDProducer("RPCTwinMuxRawToDigi",
    bxMax = cms.int32(2),
    bxMin = cms.int32(-2),
    calculateCRC = cms.bool(True),
    fillCounters = cms.bool(True),
    inputTag = cms.InputTag("rawDataCollector"),
)

process.HLTMuonLocalRecoSequence = cms.Sequence(
  process.hltMuonDTDigis
 +process.hltDt1DRecHits
 +process.hltDt4DSegments
 +process.hltMuonCSCDigis
 +process.hltCsc2DRecHits
 +process.hltCscSegments
 +process.hltMuonRPCDigisCPPF
 +process.hltOmtfDigis
 +process.hltMuonRPCDigisTwinMux
 +process.hltMuonRPCDigis
 +process.hltRpcRecHits
 +process.hltMuonGEMDigis
 +process.hltGemRecHits
 +process.hltGemSegments
)

process.HLTMuonLocalRecoMeanTimerSequence = cms.Sequence(
  process.hltMuonDTDigis
 +process.hltDt1DRecHits
 +process.hltDt4DSegmentsMeanTimer
 +process.hltMuonCSCDigis
 +process.hltCsc2DRecHits
 +process.hltCscSegments
 +process.hltMuonRPCDigisCPPF
 +process.hltOmtfDigis
 +process.hltMuonRPCDigisTwinMux
 +process.hltMuonRPCDigis
 +process.hltRpcRecHits
 +process.hltMuonGEMDigis
 +process.hltGemRecHits
 +process.hltGemSegments
)
EOF

edmConfigDump hlt.py > dump_testCMSHLT3239.py
