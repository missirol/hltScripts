#!/usr/bin/env python3
import os
import argparse
import glob
import ROOT

from DataFormats.FWLite import Runs, Events, Handle

### Event Analysis
def getRawData(label):
  handle = Handle('FEDRawDataCollection')
  event.getByLabel(label, handle)
  return handle.product()

def analyse_event(event, inputLabel1, inputLabel2, verbosity=0):

    print('-'*50)
    print('Run             =', event.eventAuxiliary().run())
    print('LuminosityBlock =', event.eventAuxiliary().luminosityBlock())
    print('Event           =', event.eventAuxiliary().event())
    print('-'*50)

    rawData1 = getRawData(inputLabel1)
    rawData2 = getRawData(inputLabel2)

    for fedId in range(4096+1):
      if fedId != 1404:
          continue

      f1 = rawData1.FEDData(fedId)
      f2 = rawData2.FEDData(fedId)
      d1 = f1.data()
      d2 = f2.data()
      s1 = f1.size()
      s2 = f2.size()
      if s1 != s2:
        print(fedId, s1, s2)
        for idx in range(max(s1,s2)):
            d1_i = d1[idx] if idx < s1 else -1
            d2_i = d2[idx] if idx < s2 else -1
            marker = 'x' if d1_i != d2_i else ''
            print(f'    {idx: >5d} {d1_i: >6d} {d2_i: >6d} {marker}')

### main
if __name__ == '__main__':
   ### args
   parser = argparse.ArgumentParser()

   parser.add_argument('-i', '--inputs', dest='inputs', required=True, nargs='+', default=None,
                       help='Path to input .root file(s)')

   parser.add_argument('-r', '--reference-rawDataLabel', dest='inputLabel1', action='store', default=None, required=True,
                       help='Label of reference FEDRawDataCollection product')

   parser.add_argument('-t', '--target-rawDataLabel', dest='inputLabel2', action='store', default=None, required=True,
                       help='Label of target FEDRawDataCollection product')

   parser.add_argument('-n', '--maxEvents', dest='maxEvents', action='store', type=int, default=-1,
                       help='Maximum number of events to be processed (inclusive)')

   parser.add_argument('-v', '--verbosity', dest='verbosity', action='store', type=int, default=0,
                       help='Level of verbosity')

   opts, opts_unknown = parser.parse_known_args()

   log_prx = os.path.basename(__file__)+' -- '

   ### args validation
   if len(opts_unknown) > 0:
     raise RuntimeError(log_prx+'unrecognized command-line arguments: '+str(opts_unknown))

   INPUT_FILES = []
   for i_inpf in opts.inputs:
     i_inpf_ls = glob.glob(i_inpf)
     if len(i_inpf_ls) == 0:
       i_inpf_ls = [i_inpf]
     for i_inpf_2 in i_inpf_ls:
       i_inpfile = os.path.abspath(os.path.realpath(i_inpf_2)) if os.path.isfile(i_inpf_2) else i_inpf_2
       INPUT_FILES += [i_inpfile]

   INPUT_FILES = sorted(list(set(INPUT_FILES)))

   if len(INPUT_FILES) == 0:
     raise RuntimeError(log_prx+'empty list of input files [-i]')

   nEvtProcessed = 0
   for i_inpf in INPUT_FILES:
       if opts.verbosity >= 10:
         print('[input]', os.path.relpath(i_inpf))

       try:
         events = Events(i_inpf)
       except:
         print(f'{log_prx}target TFile does not contain a TTree named "Events" (file will be ignored): {i_inpf}')
         continue

       eventIndex = 0
       for event in events:
         if ((opts.maxEvents >= 0) and (nEvtProcessed >= opts.maxEvents)):
           continue

         analyse_event(event=event, inputLabel1=opts.inputLabel1, inputLabel2=opts.inputLabel2, verbosity=opts.verbosity)
         nEvtProcessed += 1
         eventIndex += 1

   print('='*30)
   print('Events processed =', nEvtProcessed)
