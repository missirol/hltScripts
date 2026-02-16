#!/bin/bash

CONFIGDIR=$(dirname -- "${BASH_SOURCE[0]}")

if [ $# -ge 1 ]; then
  modAllocFilePrefix="${1}"

  LD_PRELOAD=libPerfToolsAllocMonitorPreload.so \
  cmsRun "${CONFIGDIR}"/test_l1tGlobalProducer_cfg.py -n 100 -m "${modAllocFilePrefix}".log

  edmModuleAllocMonitorAnalyze.py "${modAllocFilePrefix}".log -j > "${modAllocFilePrefix}".json

  edmModuleAllocJsonToCircles.py "${modAllocFilePrefix}".json > "${modAllocFilePrefix}"_circles.json
else
  cmsRun "${CONFIGDIR}"/test_l1tGlobalProducer_cfg.py -n 100
fi
