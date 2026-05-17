#!/bin/bash

test_run(){

OUTFILE=$1
ACCELER=$2

https_proxy=http://cmsproxy.cms:3128 \
hltGetConfiguration run:360224 \
 --data \
 --no-prescale \
 --no-output \
 --globaltag 124X_dataRun3_HLT_v4 \
 --paths AlCa_PFJet40_v* \
 --max-events -1 \
 --input file:run360224_ls0081_file1.root \
 > "${OUTFILE}".py

cat <<@EOF >> "${OUTFILE}".py
process.MessageLogger.cerr.FwkReport.limit = 1000
process.options.numberOfThreads = 1
process.options.accelerators = ['${ACCELER}']

process.source.skipEvents = cms.untracked.uint32(46)
process.maxEvents.input = 1

process.hltOutputMinimal = cms.OutputModule( "PoolOutputModule",
    fileName = cms.untracked.string( "output.root" ),
    fastCloning = cms.untracked.bool( False ),
    dataset = cms.untracked.PSet(
        dataTier = cms.untracked.string( 'AOD' ),
        filterName = cms.untracked.string( '' )
    ),
    outputCommands = cms.untracked.vstring( 'drop *',
        'keep edmTriggerResults_*_*_*',
        'keep triggerTriggerEvent_*_*_*',
        'keep *_hltSiPixelClusters*_*_*',
        'keep *_hltSiPixelRecHits*_*_*',
        'keep *_hltPixelTracks*_*_*',
    )
)
process.MinimalOutput = cms.FinalPath( process.hltOutputMinimal )
process.schedule.append( process.MinimalOutput )
@EOF

cmsRun "${OUTFILE}".py &> "${OUTFILE}".log
}

write_analyser(){

cat <<@EOF > $1
#!/usr/bin/env python3
import os
import argparse
import glob
import ROOT

from DataFormats.FWLite import Runs, Events, Handle

### Utilities
def colored_text(txt, keys=[]):
    return txt
#    _tmp_out = ''
#    for _i_tmp in keys:
#        _tmp_out += '\033['+_i_tmp+'m'
#    _tmp_out += txt
#    if len(keys) > 0: _tmp_out += '\033[0m'
#    return _tmp_out

### Event Analysis
def analyse_event(event, verbosity=0):

    if verbosity >= 0:
      print('-'*50)
      print('Run             =', event.eventAuxiliary().run())
      print('LuminosityBlock =', event.eventAuxiliary().luminosityBlock())
      print('Event           =', event.eventAuxiliary().event())
      print('-'*50)

    if verbosity >= 0:
      TriggerResultsInputTagLabel = 'TriggerResults'
      TriggerResultsHandle = Handle('edm::TriggerResults')
      event.getByLabel(TriggerResultsInputTagLabel, TriggerResultsHandle)
      TriggerResults = TriggerResultsHandle.product()
      triggerNames = event.object().triggerNames(TriggerResults).triggerNames()
      print('\nTriggerResults = "'+TriggerResultsInputTagLabel+'"'+f' [{len(triggerNames)} Paths]')

      if verbosity >= 1:
        print('')
        for triggerNameIdx, triggerName in enumerate(triggerNames):
          triggerNameIdxStr = '['+str(triggerNameIdx)+']'
          print(f'{triggerNameIdxStr:>6} | {int(TriggerResults.accept(triggerNameIdx))} | {str(triggerName)}')

    hltPixelTracksInputTagLabel = 'hltPixelTracks'
    hltPixelTracksHandle = Handle('std::vector<reco::Track>')
    event.getByLabel(hltPixelTracksInputTagLabel, hltPixelTracksHandle)
    hltPixelTracks = hltPixelTracksHandle.product()

    if verbosity >= 0:
      print('\n'+'-'*20)
      for hltPixelTrack_idx in range(len(hltPixelTracks)):
        print('hltPixelTracks CAND {:9.4f} {:9.4f} {:9.4f}'.format(
          hltPixelTracks[hltPixelTrack_idx].pt(), hltPixelTracks[hltPixelTrack_idx].eta(), hltPixelTracks[hltPixelTrack_idx].phi())
        )
### main
if __name__ == '__main__':
   ### args
   parser = argparse.ArgumentParser()

   parser.add_argument('-i', '--inputs', dest='inputs', required=True, nargs='+', default=None,
                       help='path to input .root file(s)')

#   parser.add_argument('-o', '--output', dest='output', action='store', default=None,
#                       help='path to output .root file')

   parser.add_argument('-e', '--every', dest='every', action='store', type=int, default=1e2,
                       help='show progress of processing every N events')

   parser.add_argument('-s', '--skipEvents', dest='skipEvents', action='store', type=int, default=0,
                       help='index of first event to be processed (inclusive)')

   parser.add_argument('-n', '--maxEvents', dest='maxEvents', action='store', type=int, default=-1,
                       help='maximum number of events to be processed (inclusive)')

   parser.add_argument('-v', '--verbosity', dest='verbosity', action='store', type=int, default=0,
                       help='level of verbosity')

   opts, opts_unknown = parser.parse_known_args()

   log_prx = os.path.basename(__file__)+' -- '

   ### args validation
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

#   if (opts.output is not None) and os.path.exists(opts.output):
#     raise RuntimeError(log_prx+'target path to output .root file already exists [-o]: '+opts.output)

   SHOW_EVERY = opts.every
   if SHOW_EVERY <= 0:
     print(log_prx+'invalid (non-positive) value for option "-e/--every" ('+str(SHOW_EVERY)+'), value will be changed to 100')
     SHOW_EVERY = 1e2

   if len(opts_unknown) > 0:
     raise RuntimeError(log_prx+'unrecognized command-line arguments: '+str(opts_unknown))

   ## histograms
   nEvtProcessed = 0

   for i_inpf in INPUT_FILES:

       if opts.verbosity >= 10:
         print(colored_text('[input]', ['1','94']), os.path.relpath(i_inpf))

       try:
         events = Events(i_inpf)
       except:
         print(log_prx+'target TFile does not contain a TTree named "Events" (file will be ignored) [-t]: '+i_inpf)
         continue

       skipEvents = 0 if opts.skipEvents < 0 else opts.skipEvents

       eventIndex = 0
       for event in events:
         if (eventIndex < skipEvents) or ((opts.maxEvents >= 0) and (nEvtProcessed >= opts.maxEvents)):
           continue

         if (not (eventIndex % SHOW_EVERY)) and (eventIndex > 0):
           print('-'*10)
           print('Event #'+str(eventIndex))

         analyse_event(event=event, verbosity=opts.verbosity)
         nEvtProcessed += 1
         eventIndex += 1

   print('='*30)
   print(colored_text('Events processed =', ['1']), nEvtProcessed)
@EOF
}

write_analyser check.py

OUTDIR=out_cpu
rm -rf "${OUTDIR}"
mkdir -p "${OUTDIR}"
for ddd in {0..9}; do
  echo try "${ddd}"
  test_run hlt cpu
  mv hlt.log "${OUTDIR}"/hlt"${ddd}".log
  mv output.root "${OUTDIR}"/hlt"${ddd}".root
  ./check.py -i "${OUTDIR}"/hlt"${ddd}".root -n 1 -v 10 \
    | grep CAND | sort -u > "${OUTDIR}"/hlt"${ddd}".txt
done
unset ddd

OUTDIR=out_gpu
rm -rf "${OUTDIR}"
mkdir -p "${OUTDIR}"
for ddd in {0..9}; do
  echo try "${ddd}"
  test_run hlt gpu-nvidia
  mv hlt.log "${OUTDIR}"/hlt"${ddd}".log
  mv output.root "${OUTDIR}"/hlt"${ddd}".root
  ./check.py -i "${OUTDIR}"/hlt"${ddd}".root -n 1 -v 10 \
    | grep CAND | sort -u > "${OUTDIR}"/hlt"${ddd}".txt
done
unset ddd
