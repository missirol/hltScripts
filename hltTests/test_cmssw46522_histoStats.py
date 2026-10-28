#!/usr/bin/env python3
import ROOT
import sys
import os

inputFile = sys.argv[1]

inputFileSize = os.stat(inputFile).st_size

f0 = ROOT.TFile.Open(inputFile)

def getSize(obj):
  b0 = ROOT.TBufferFile(ROOT.TBuffer.kWrite, 10000000)
  ROOT.TClass.GetClass(obj.ClassName()).WriteBuffer(b0, obj)
  return b0.Length()

def getListOfKeys(obj):
    ret = []
    for key_i in obj.GetListOfKeys():
        key_i_name = key_i.GetName()
        obj_i = obj.Get(key_i_name)
        try:
            if obj_i.InheritsFrom('TDirectory'):
                ret += [f'{key_i_name}/{foo}' for foo in getListOfKeys(obj_i)]
            elif obj_i.InheritsFrom('TH1'):
                ret += [key_i_name]
        except:
            ret += [key_i_name]
    return ret

listOfKeyNames = sorted(list(set(getListOfKeys(f0))))

totalSize = 0
for keyName_i in listOfKeyNames:
    obj_i = f0.Get(keyName_i)
    try:
        objSize_i = getSize(obj_i)
        objSizeLabel_i = f'{objSize_i:>20d}'
        totalSize += objSize_i
    except:
        objSizeLabel_i = 'N/A'
    print(f'{objSizeLabel_i} {keyName_i: <20}')

#print(totalSize, inputFileSize)
