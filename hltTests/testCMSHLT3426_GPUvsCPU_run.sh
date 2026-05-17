#!/bin/bash

./testCMSHLT3426_GPUvsCPU.py hlt1500p2
./testCMSHLT3426_GPUvsCPU.py hlt1500p3

for nnn in hlt1500p2_try0 hlt1500p2_try1 hlt1500p3_try0 hlt1500p3_try1; do
  hltTests/testCMSHLT3426_GPUvsCPU.sh $nnn
done
unset nnn

./testCMSHLT3426_GPUvsCPU_hltDiff.sh
