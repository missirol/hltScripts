#!/bin/bash -ex

jobLabel=hlt1
if [ ! -f "${jobLabel}".py ]; then
  hltGetConfiguration \
   /dev/CMSSW_13_2_0/GRun \
   --paths HLT_VBF_DiPFJet*,-HLT_VBF_DiPFJet*Detajj*,HLTriggerFinalPath \
   --max-events 1000 \
   --output minimal --no-prescale \
   --mc --globaltag 126X_mcRun3_2023_forPU65_v5 \
   --input /store/mc/Run3Winter23Digi/VBFHHto2B2Tau_CV-1_C2V-2_C3-1_TuneCP5_13p6TeV_madgraph-pythia8/GEN-SIM-RAW/126X_mcRun3_2023_forPU65_v1-v2/40000/a94d16bb-8df9-4eab-8c89-a5594aef6a48.root \
   --eras Run3 --l1-emulator FullMC --l1 L1Menu_Collisions2023_v1_3_0_xml \
   > "${jobLabel}".py
  cat <<EOF >> "${jobLabel}".py
process.options.numberOfThreads = 1
process.options.numberOfStreams = 0
EOF
  echo -e "\n=== ${jobLabel} ==="
  edmConfigDump "${jobLabel}".py > "${jobLabel}"_dump.py
  cmsRun "${jobLabel}".py &> "${jobLabel}".log
  mv output.root "${jobLabel}".root
  grep TrigRepor "${jobLabel}".log | head -20
else
  echo "Skipping ${jobLabel}"
fi

# customise using the new filter without changing the cuts in any HLT Paths (expect same exact trigger results)
jobLabel=hlt2
if [ ! -f "${jobLabel}".py ]; then
  cp hlt1.py "${jobLabel}".py
  cat <<EOF >> "${jobLabel}".py
from HLTrigger.JetMET.hltL1TMatchedPFJetsVBFFilter_cfi import hltL1TMatchedPFJetsVBFFilter as _hltL1TMatchedPFJetsVBFFilter

def _redefineLastFilterOfVBFParkingPaths(process, producerLabel, filterLabels):

    mod_p = getattr(process, producerLabel)

    for filterLabel in filterLabels:
        mod_f = getattr(process, filterLabel)

        setattr(process, filterLabel, _hltL1TMatchedPFJetsVBFFilter.clone(
            src = mod_p.JetSrc,
            maxJetDeltaR = mod_p.matchingR,
            l1tJetRefs = mod_p.L1JetTrigger,
            algorithm = mod_p.matchingMode,
            minPt1 = mod_p.pt1Min,
            minPt2 = mod_p.pt2Min,
            minPt3 = mod_p.pt3Min,
            minInvMass = mod_p.mjjMin,
            minNJets = mod_f.MinN,
            maxNJets = mod_f.MinN
        ))

    delattr(process, producerLabel)

    return process

_fooDict = {
    'hltL1PFJetsMatchingVBFinclMedium1050': ['hltL1PFJetCategoriesVBFinclMedium1050', 'hltL1PFJetCategoriesVBFinclMedium1050TripleJet'],
    'hltL1PFJetsMatchingVBFinclTight1050': ['hltL1PFJetCategoriesVBFinclTight1050', 'hltL1PFJetCategoriesVBFinclTight1050TripleJet'],
    'hltL1TPFJetsMatchingVBFDijetTight650': ['hltL1PFJetCategoriesVBFdijetTightQuadjet650', 'hltL1PFJetCategoriesVBFdijetTightFivejet650', 'hltL1PFJetCategoriesVBFdijetTightSixjet650'],
    'hltL1PFJetsMatchingVBFMETTight550': ['hltL1PFJetCategoriesVBFMETTight550', 'hltL1PFJetCategoriesVBFMETTight550Triplejet'],
    'hltL1PFJetsMatchingVBFMuTight650': ['hltL1PFJetCategoriesVBFMuTight650', 'hltL1PFJetCategoriesVBFMuTight650Triplejet'],
}

for key,val in _fooDict.items():
    process = _redefineLastFilterOfVBFParkingPaths(process, key, val)
EOF
  echo -e "\n=== ${jobLabel} ==="
  edmConfigDump "${jobLabel}".py > "${jobLabel}"_dump.py
  cmsRun "${jobLabel}".py &> "${jobLabel}".log
  mv output.root "${jobLabel}".root
  grep TrigRepor "${jobLabel}".log | head -20
else
  echo "Skipping ${jobLabel}"
fi

# customise fully (new filter, "merge" paths using maxNJets=-1),
# expect remaining Paths to the logical OR of the old ones (hlt1)
jobLabel=hlt3
if [ ! -f "${jobLabel}".py ]; then
  cp hlt1.py "${jobLabel}".py
  cat <<EOF >> "${jobLabel}".py
from HLTrigger.JetMET.hltL1TMatchedPFJetsVBFFilter_cfi import hltL1TMatchedPFJetsVBFFilter as _hltL1TMatchedPFJetsVBFFilter

def _redefineLastFilterOfVBFParkingPaths(process, producerLabel, filterLabels):

    mod_p = getattr(process, producerLabel)

    for filterLabel in filterLabels:
        mod_f = getattr(process, filterLabel)

        setattr(process, filterLabel, _hltL1TMatchedPFJetsVBFFilter.clone(
            src = mod_p.JetSrc,
            maxJetDeltaR = mod_p.matchingR,
            l1tJetRefs = mod_p.L1JetTrigger,
            algorithm = mod_p.matchingMode,
            minPt1 = mod_p.pt1Min,
            minPt2 = mod_p.pt2Min,
            minPt3 = mod_p.pt3Min,
            minInvMass = mod_p.mjjMin,
            minNJets = mod_f.MinN,
            maxNJets = -1
        ))

    delattr(process, producerLabel)

    return process

_fooDict = {
    'hltL1PFJetsMatchingVBFinclMedium1050': ['hltL1PFJetCategoriesVBFinclMedium1050'],
    'hltL1PFJetsMatchingVBFinclTight1050': ['hltL1PFJetCategoriesVBFinclTight1050'],
    'hltL1TPFJetsMatchingVBFDijetTight650': ['hltL1PFJetCategoriesVBFdijetTightQuadjet650'],
    'hltL1PFJetsMatchingVBFMETTight550': ['hltL1PFJetCategoriesVBFMETTight550'],
    'hltL1PFJetsMatchingVBFMuTight650': ['hltL1PFJetCategoriesVBFMuTight650'],
}

for key,val in _fooDict.items():
    process = _redefineLastFilterOfVBFParkingPaths(process, key, val)

for foo in [foo for foo in process.paths_() if '_TriplePFJet_v' in foo or 'FiveJet_v' in foo or 'SixJet_v' in foo]:
    delattr(process, foo)
EOF
  echo -e "\n=== ${jobLabel} ==="
  edmConfigDump "${jobLabel}".py > "${jobLabel}"_dump.py
  cmsRun "${jobLabel}".py &> "${jobLabel}".log
  mv output.root "${jobLabel}".root
  grep TrigRepor "${jobLabel}".log | head -20
else
  echo "Skipping ${jobLabel}"
fi
