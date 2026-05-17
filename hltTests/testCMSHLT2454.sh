https_proxy=http://cmsproxy.cms:3128/ hltGetConfiguration \
   /users/missirol/test/dev/CMSSW_12_4_0/CMSHLT_2454/Test01/HLT/V4 \
   --globaltag 124X_dataRun3_HLT_v4 \
   --data \
   --unprescale \
   --output minimal \
   --max-events 100 \
   --eras Run3 --l1-emulator FullMC --l1 L1Menu_Collisions2022_v1_3_0-d1_xml \
   --input /store/data/Run2022C/EGamma/RAW/v1/000/355/872/00000/3b478527-d206-4b8e-8004-08e9aff7758b.root \
   > hlt.py

#   --paths DQM_*,*GPUvsCPU* \
#   --paths MC_PFJet*,AlCa_*,DQM_*,*GPUvsCPU* \

cat <<@EOF >> hlt.py

del process.DQMHistograms
#del process.DQM_EcalReconstruction_v3
process.hltEcalConsumerCPU.eventProducts.remove('hltEcalDigis@cpu')
#process.hltEcalConsumerCPU.eventProducts[0] = 'hltEcalDigisLegacy'
#process.options.accelerators = ['cpu']

process.hltDatasetDQMGPUvsCPU.triggerConditions = [
  'DQM_EcalReconstruction_v3',
  'DQM_HcalReconstruction_v3',
  'DQM_PixelReconstruction_v3',
]

pathNames = process.paths_().keys()
for pathName in pathNames:
  if 'HI' in pathName:
    process.__delattr__(pathName)

finalPathNames = process.finalpaths_().keys()
for finalPathName in finalPathNames:
  if finalPathName != 'DQMGPUvsCPUOutput':
    process.__delattr__(finalPathName)
@EOF

cmsRun hlt.py &> hlt.log
