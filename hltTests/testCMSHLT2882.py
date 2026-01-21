#!/usr/bin/env python3

# CMSSW_13_3_X_2023-09-02-1100
# hltConfigFromDB --configName /users/soohwan/HLT_132X/HLT_PbPb_notrk_noZDC_v4_fromDener > hion.py

from hion import cms,process
from HLTrigger.Configuration.HLT_HIon_cff import fragment

def getPathNames(process):
    return sorted([foo for foo in process.paths_()])

def getPathNamesUnv(process):
    return [foo[:foo.rfind('_v')]+'_v*' if '_v' in foo else foo for foo in getPathNames(process)]

oldPathsUnv = getPathNamesUnv(fragment)
newPathsUnv = getPathNamesUnv(process)

oldPaths = getPathNames(fragment)
newPaths = getPathNames(process)

removePaths = []
for idx,bar in enumerate(oldPathsUnv):
    if bar not in newPathsUnv:
        print(oldPaths[idx])
        removePaths.append(bar)

newlines = []
with open('HLTrigger/Configuration/tables/HIon.txt','r') as ftable:
    lines = ftable.read().splitlines()
    for foo in lines:
        skipLine = False
        for bar in removePaths:
            if bar in foo:
                skipLine = True
                break
        if not skipLine:
            newlines.append(foo)

with open('HLTrigger/Configuration/tables/HIon.txt','w') as ftable:
    for foo in newlines:
        ftable.write(foo+'\n')

brokenPaths = [
 'HLT_HIDmesonPPTrackingGlobal_Dpt20',
 'HLT_HIDmesonPPTrackingGlobal_Dpt30',
 'HLT_HIDmesonPPTrackingGlobal_Dpt40',
 'HLT_HIDmesonPPTrackingGlobal_Dpt50',
 'HLT_HIDmesonPPTrackingGlobal_Dpt60',
 'HLT_HIDmesonPPTrackingGlobal_Dpt20_NoIter10',
 'HLT_HIDmesonPPTrackingGlobal_Dpt30_NoIter10',
 'HLT_HIDmesonPPTrackingGlobal_Dpt40_NoIter10',
 'HLT_HIDmesonPPTrackingGlobal_Dpt50_NoIter10',
 'HLT_HIDmesonPPTrackingGlobal_Dpt60_NoIter10',
 'HLT_HIDsPPTrackingGlobal_Dpt20',
 'HLT_HIDsPPTrackingGlobal_Dpt30',
 'HLT_HIDsPPTrackingGlobal_Dpt40',
 'HLT_HIDsPPTrackingGlobal_Dpt50',
 'HLT_HIDsPPTrackingGlobal_Dpt60',
 'HLT_HIDsPPTrackingGlobal_Dpt20_NoIter10',
 'HLT_HIDsPPTrackingGlobal_Dpt30_NoIter10',
 'HLT_HIDsPPTrackingGlobal_Dpt40_NoIter10',
 'HLT_HIDsPPTrackingGlobal_Dpt50_NoIter10',
 'HLT_HIDsPPTrackingGlobal_Dpt60_NoIter10',
 'HLT_HILcPPTrackingGlobal_Dpt20',
 'HLT_HILcPPTrackingGlobal_Dpt30',
 'HLT_HILcPPTrackingGlobal_Dpt40',
 'HLT_HILcPPTrackingGlobal_Dpt50',
 'HLT_HILcPPTrackingGlobal_Dpt60',
 'HLT_HILcPPTrackingGlobal_Dpt20_NoIter10',
 'HLT_HILcPPTrackingGlobal_Dpt30_NoIter10',
 'HLT_HILcPPTrackingGlobal_Dpt40_NoIter10',
 'HLT_HILcPPTrackingGlobal_Dpt50_NoIter10',
 'HLT_HILcPPTrackingGlobal_Dpt60_NoIter10',
 'HLT_HIFullTracks2018_HighPt18',
 'HLT_HIFullTracks2018_HighPt24',
 'HLT_HIFullTracks2018_HighPt34',
 'HLT_HIFullTracks2018_HighPt45',
 'HLT_HIFullTracks2018_HighPt56',
 'HLT_HIFullTracks2018_HighPt60',
 'HLT_HIFullTracks2018_HighPt18_NoIter10',
 'HLT_HIFullTracks2018_HighPt24_NoIter10',
 'HLT_HIFullTracks2018_HighPt34_NoIter10',
 'HLT_HIFullTracks2018_HighPt45_NoIter10',
 'HLT_HIFullTracks2018_HighPt56_NoIter10',
 'HLT_HIFullTracks2018_HighPt60_NoIter10',
]

for foo in brokenPaths:
    if foo+'_v*' in newPathsUnv:
        print('!!!!!!!!!!!!!', foo)
