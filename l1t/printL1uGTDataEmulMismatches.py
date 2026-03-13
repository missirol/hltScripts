#!/usr/bin/env python3
import ROOT

runNumber = 401803

# DQM file to be downloaded from https://cmsweb.cern.ch/dqm/offline/data/browse/ROOT/OnlineData/original/
fileName = f'DQM_V0001_L1TEMU_R000{runNumber}.root'

print('='*100)
print(fileName)
print('='*100)

file0 = ROOT.TFile.Open(fileName)

histDirName = f'DQMData/Run {runNumber}/L1TEMU/Run summary/L1TdeStage2uGT/InitialDecisionMismatches'
histNames = []
for histBaseName1 in ['DataNoEmul', 'EmulatorNoData']:
    for histBaseName2 in ['BX-2', 'BX-1', 'CentralBX', 'BX1', 'BX2']:
        histNames += [f'{histDirName}/{histBaseName1}_{histBaseName2}']

for histName in histNames:
    h0 = file0.Get(histName)
    print(histName)
    for binIdx in range(1, 1+h0.GetNbinsX()):
        binVal = h0.GetBinContent(binIdx)
        if binVal > 0:
            print(f'    {h0.GetXaxis().GetBinCenter(binIdx)} ({binVal})')
