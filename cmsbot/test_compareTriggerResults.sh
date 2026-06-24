#!/bin/sh -ex

REF_DIR=ref
TAR_DIR=tar
WF_DIR=18434.0_TTbar_14TeV+2026
CMS_BOT_DIR=.
CMSBOT_PYTHON_CMD=python3

rm -rf tmp_triggerResults
mkdir -p tmp_triggerResults

for file_basename in compareTriggerResults.py compareTriggerResultsSummary.py; do
  file_path="${CMS_BOT_DIR}"/"${file_basename}"
  if [ -f "${file_path}" ]; then
    continue
  fi
  wget https://raw.githubusercontent.com/cms-sw/cms-bot/refs/heads/master/"${file_basename}" \
    -O "${file_path}"
done

${CMSBOT_PYTHON_CMD} ${CMS_BOT_DIR}/compareTriggerResults.py -r ${REF_DIR} -t ${TAR_DIR} \
 -f "*/${WF_DIR}/step*.root" -o tmp_triggerResults

${CMSBOT_PYTHON_CMD} ${CMS_BOT_DIR}/compareTriggerResultsSummary.py -i tmp_triggerResults \
 -f "*/*.json" -o tmp_triggerResults/index.html -F html
