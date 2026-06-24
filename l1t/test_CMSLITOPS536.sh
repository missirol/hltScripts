#!/bin/bash -ex

run_test() {

  JOB_LABEL="${1}"
  MAXEVENTS="${2}"
  INPUTFILE="${3}"

  cmsDriver.py "${JOB_LABEL}" --process TEST \
    --repacked \
    --data --conditions 161X_dataRun3_Prompt_v1 --geometry DB:Extended \
    --scenario pp --era Run3_2026 \
    --datatier NANOAOD --eventcontent NANOAOD \
    --nThreads 8 --nStreams 0 \
    --filein "${INPUTFILE}" \
    --python_filename "${JOB_LABEL}"_cfg.py \
    --fileout file:"${JOB_LABEL}"_out.root \
    -s RAW2DIGI,NANO:@L1DPG -n "${MAXEVENTS}" \
    2>&1 | tee "${JOB_LABEL}".log

  rm -rf __pycache__
}

cat <<@EOF > printCaloTowers.py
#!/usr/bin/env python3
import argparse
import math
import ROOT

parser = argparse.ArgumentParser(
    description='Print the content of the CaloTowers branches of a NanoAOD file (L1T-DPG NanoAOD flavour)',
    formatter_class=argparse.ArgumentDefaultsHelpFormatter)

parser.add_argument('-i', '--input-file', type=str, required=True,
    help='Path to input NanoAOD file')

parser.add_argument('-o', '--output-file', type=str, default='tmp.txt',
    help='Path to output text file')

parser.add_argument('-n', '--maxEvents', type=int, default=-1,
    help='Max number of events to be processed (ignored if negative)')

parser.add_argument('-l', '--caloTowerLabel', type=str,
    default="L1UnpackedCaloTower", choices=["L1UnpackedCaloTower", "L1EmulCaloTower"],
    help='Prefix of the names of the CaloTowers branches in the input NanoAOD file')

args = parser.parse_args()

tfile = ROOT.TFile.Open(args.input_file)
ttree = tfile.Get('Events')
nEvents = ttree.GetEntries()

print('-'*50)
print(f'Input file: {args.input_file} ({nEvents} events)')
print(f'Output file: {args.output_file}')
print(f'CaloTowers label: "{args.caloTowerLabel}"')
print('-'*50)
print(f'Started processing events..\n')

eventsToProcess = min(args.maxEvents, nEvents) if args.maxEvents >= 0 else nEvents
reportEvery = max(1, math.pow(10, round(math.log(eventsToProcess / 10, 10))))

eventCounter = 0

with open(args.output_file, 'w') as outf:
    outf.write(50*'='+'\n')
    outf.write(f'Input file: {args.input_file}\n')
    outf.write(f'CaloTowers label: "{args.caloTowerLabel}"\n')
    outf.write('Columns: (hwEt, hwEta, hwPhi, erBits, miscBits)\n')
    outf.write(50*'='+'\n')

    for e0 in ttree:
        if args.maxEvents >= 0 and eventCounter >= args.maxEvents:
            break

        if eventCounter > 0 and eventCounter % reportEvery == 0:
            print(f'Processed {eventCounter} events..')

        cts = []
        for ct_idx in range(getattr(e0, f'n{args.caloTowerLabel}')):
            cts += [[
                getattr(e0, f'{args.caloTowerLabel}_ieta')[ct_idx],
                getattr(e0, f'{args.caloTowerLabel}_iphi')[ct_idx],
                getattr(e0, f'{args.caloTowerLabel}_iet')[ct_idx],
                getattr(e0, f'{args.caloTowerLabel}_iratio')[ct_idx],
                getattr(e0, f'{args.caloTowerLabel}_iqual')[ct_idx],
            ]]
        cts.sort()

        outf.write('\n'+50*'-'+'\n')
        outf.write(f'run:luminosityBlock:event = {e0.run}:{e0.luminosityBlock}:{e0.event}\n')
        outf.write(50*'-'+'\n')
        for ct in cts:
            outf.write(f'{ct[2]:>5d} {ct[0]:>5d} {ct[1]:>5d} {ct[3]:>5d} {ct[4]:>5d}\n')
        outf.write(50*'-'+'\n')

        eventCounter += 1

assert eventCounter == eventsToProcess
print(f'\nProcessing completed ({eventCounter} events)')
@EOF

###
### diff (ref vs tar)
###

run_test "${1}" "${2}" file:"${3}"

for outPrefix in "${1}"_out; do
  for caloTowersLabel in L1UnpackedCaloTower L1EmulCaloTower; do
    python3 printCaloTowers.py -n -1 \
      -i "${outPrefix}".root -l "${caloTowersLabel}" \
      -o "${outPrefix}"_"${caloTowersLabel}".txt
  done
done

printf "%s\n" "================================================"
printf "%s\n" "Diff: unpacked vs emulated"
printf "%s\n" "================================================"
diff -q "${1}"_out_*.txt || true
