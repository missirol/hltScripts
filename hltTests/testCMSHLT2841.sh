#!/bin/bash

hltConfigFromDB --configName /dev/CMSSW_13_0_0/HLT/V149 \
  --blocks hltOutputReleaseValidation::outputCommands > tmp.py

cat <<EOF >> tmp.py
import fnmatch

theModules = sorted(list(set(
   list(process.filters_().keys())
 + list(process.producers_().keys())
 + list(process.switchProducers_().keys())
)))

theProducts = []
for foo in block_hltOutputReleaseValidation.outputCommands:
    if not foo.startswith('keep '):
        continue
    theProductName = foo[5:].split('_')[1]
    if theProductName != "*":
        theProducts.append(theProductName)

for bar in theProducts:
    productMightExist = False
    for foo in theModules:
        if fnmatch.fnmatch(foo, bar):
            productMightExist = True
            break
    if not productMightExist:
        print(bar)
EOF

python3 tmp.py
