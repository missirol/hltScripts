#!/bin/bash

hltGetConfiguration \
  /users/missirol/test/dev/CMSSW_14_0_0/CMSHLT_3089/Test01/GRun/V2 \
  --globaltag 140X_dataRun3_HLT_v1 \
  --max-events 1000000 \
  --input foo.root \
  --paths "DST_PFScouting*,Dataset_*Scouting*Run3,-*DatasetMuon*" \
  --l1 L1Menu_Collisions2024_v0_0_0_xml \
  --no-prescale \
  > hlt.py

cat <<@EOF >> hlt.py

del process.MessageLogger
process.load('FWCore.MessageLogger.MessageLogger_cfi')

process.options.numberOfThreads = 4
process.options.numberOfStreams = 0

process.hltDatasetScoutingPFRun3.triggerConditions = [
    'DST_PFScouting_DoubleEG_v1',
    'DST_PFScouting_DoubleMuon_v1',
    'DST_PFScouting_SingleMuon_v1',
    'DST_PFScouting_JetHT_v1',
    'DST_PFScouting_AXONominal_v1',
    'DST_PFScouting_AXOTight_v1',
]

for foo in [foo for foo in process.finalpaths_() if foo != 'ScoutingPFOutput']:
  process.__delattr__(foo)

process.hltOutputScoutingPF.compressionAlgorithm = 'LZMA'
process.hltOutputScoutingPF.compressionLevel = 4

process.source.fileNames = [
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_0.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_1.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_10.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_100.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_101.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_102.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_103.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_104.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_105.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_106.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_107.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_108.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_109.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_11.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_110.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_111.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_112.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_113.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_114.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_115.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_116.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_117.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_118.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_119.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_12.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_120.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_121.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_122.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_123.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_124.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_125.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_126.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_127.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_128.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_129.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_13.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_130.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_131.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_132.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_133.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_134.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_135.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_136.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_137.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_138.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_139.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_14.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_140.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_141.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_142.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_143.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_144.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_145.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_146.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_147.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_148.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_149.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_15.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_150.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_151.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_152.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_153.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_154.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_155.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_156.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_157.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_158.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_159.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_16.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_160.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_161.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_162.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_163.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_164.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_165.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_166.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_167.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_168.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_169.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_17.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_170.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_171.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_172.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_173.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_174.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_175.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_176.root',
'/store/group/dpg_trigger/comm_trigger/TriggerStudiesGroup/STEAM/savarghe/L1Skim/2024_Skim/L1Menu_Collisions2024_v0_0_0_Full/L1_177.root',
]
@EOF

edmConfigDump hlt.py > hlt_dump.py

cmsRun hlt.py &> hlt.log
