#!/usr/bin/env python3
import os
import csv
import json
import argparse
import subprocess

import FWCore.ParameterSet.Config as cms
import HLTrigger.Configuration.Tools.options as options
from HLTrigger.Configuration.extend_argparse import *

def MKDIRP(dirpath, verbose=False, dry_run=False):
  if verbose:
    print('\033[1m'+'>'+'\033[0m'+' os.mkdirs("'+dirpath+'")')
  if dry_run:
    return
  try:
    os.makedirs(dirpath)
  except OSError:
    if not os.path.isdir(dirpath):
      raise

def colored_text(txt, keys=[]):
  _tmp_out = ''
  for _i_tmp in keys:
    _tmp_out += '\033['+_i_tmp+'m'
  _tmp_out += txt
  if len(keys) > 0:
    _tmp_out += '\033[0m'
  return _tmp_out

def getHLTProcess(config):
  if config.menu.run:
    configline = f'--runNumber {config.menu.run}'
  else:
    configline = f'--{config.menu.database} --{config.menu.version} --configName {config.menu.name}'

  # cmd to download HLT configuration
  cmdline = f'hltConfigFromDB {configline} --noedsources --noes --nooutput'
  if config.proxy:
    cmdline += f' --dbproxy --dbproxyhost {config.proxy_host} --dbproxyport {config.proxy_port}'

  # download HLT configuration
  proc = subprocess.Popen(cmdline, shell = True, stdin = None, stdout = subprocess.PIPE, stderr = None)
  (out, err) = proc.communicate()

  # load HLT configuration
  try:
    foo = {'process': None}
    exec(out, foo)
    process = foo['process']
  except:
    raise Exception(f'query did not return a valid python file:\n query="{cmdline}"')

  if not isinstance(process, cms.Process):
    raise Exception(f'query did not return a valid HLT menu:\n query="{cmdline}"')

  return process

def getPrescaleTableLines(process, pathNames):
  ret = []
  if hasattr(process, 'PrescaleService'):
    ret += [['Path']+process.PrescaleService.lvl1Labels]
    ncols = len(process.PrescaleService.lvl1Labels)
    psDict = {pset_i.pathName.value():pset_i.prescales for pset_i in process.PrescaleService.prescaleTable}
    for pathName in pathNames:
      if pathName not in process.paths_():
        raise SystemExit(f'getPrescaleTableLines: {pathName}')
      psvals = psDict[pathName] if pathName in psDict else [1]*ncols
      ret += [[pathName]+[str(psval_i) for psval_i in psvals]]
  return ret

def getPrescale(process, pathName, psColumnName):
  ret = ''
  if not hasattr(process, 'PrescaleService'):
    return ret
  psColIndex = -1
  for psColIdx_i, psColName_i in enumerate(process.PrescaleService.lvl1Labels):
    if psColName_i == psColumnName:
      psColIndex = psColIdx_i
  if psColIndex < 0:
    return ret
  ret = '1'
  for pset_i in process.PrescaleService.prescaleTable:
    if pathName == pset_i.pathName:
      ret = f'{pset_i.prescales[psColIndex]}'
      break
  return ret

def getDatasets(process, pathName):
  # format: "PD1 (smartPSinPD1), PD2 (smartPSinPD2), .."
  ret = []
  datasets = [dataset_i for dataset_i in process.datasets.parameterNames_() \
    if pathName in process.datasets.getParameter(dataset_i)]
  for dataset_i in datasets:
    datasetLabel = dataset_i
    # if the DatasetPath exists, add value of smart-prescale
    if hasattr(process, 'Dataset_'+dataset_i):
      datasetPath_i = getattr(process, 'Dataset_'+dataset_i)
      if isinstance(datasetPath_i, cms.Path):
        for modName in datasetPath_i.moduleNames():
          module = getattr(process, modName)
          if module.type_() == 'TriggerResultsFilter':
            if hasattr(module, 'triggerConditions'):
              for trigCond_j in module.triggerConditions:
                trigCond_j_split = trigCond_j.split(' / ')
                if trigCond_j_split[0] == pathName and len(trigCond_j_split) > 1:
                  datasetLabel += f'({trigCond_j_split[1]})'
    ret += [datasetLabel]
  return ', '.join(ret)

def getStreams(process, pathName):
  # format: "Stream1, Stream2, .."
  datasets = [dataset_i for dataset_i in process.datasets.parameterNames_() \
    if pathName in process.datasets.getParameter(dataset_i)]
  streams = [stream_i for stream_i in process.streams.parameterNames_() \
    for dataset_i in datasets if dataset_i in process.streams.getParameter(stream_i)]
  return ', '.join(streams)

def getL1TSeed(process, pathName):
  ret = ''
  path = process.paths_()[pathName]
  minIdx = None
  for modName in path.moduleNames():
    module = getattr(process, modName)
    try: modIdx = path.index(module)
    except: continue
    if module.type_() == 'HLTL1TSeed':
      if hasattr(module, 'L1SeedsLogicalExpression'):
        if minIdx == None or modIdx < minIdx:
          ret = module.L1SeedsLogicalExpression.value()
          minIdx = modIdx
  return ret

def getDatasetStreamDict(process):
  # key: "Dataset", value: list of "Streams"
  ret = {}
  for dataset_i in process.datasets.parameterNames_():
    ret[dataset_i] = []
    for stream_i in process.streams.parameterNames_():
      if dataset_i in process.streams.getParameter(stream_i):
        ret[dataset_i].append(stream_i)
    ret[dataset_i] = sorted(list(set(ret[dataset_i])))
  return ret

def create_csv(outputFilePath, delimiter, lines):
  # create output directory
  MKDIRP(os.path.dirname(outputFilePath))
  # write .csv file
  with open(outputFilePath, 'w') as csvfile:
    outf = csv.writer(csvfile, delimiter=delimiter)
    for line_i in lines:
      outf.writerow(line_i)
  print(colored_text(outputFilePath, ['1']))

def main():
  # define an argparse parser to parse our options
  textwidth = int( 80 )
  try:
    textwidth = int( os.popen("stty size", "r").read().split()[1] )
  except:
    pass
  formatter = FixedWidthFormatter( HelpFormatterRespectNewlines, width = textwidth )

  # read defaults
  defaults = options.HLTProcessOptions()

  parser = argparse.ArgumentParser(
    description       = 'Create outputs to announce the release of a new HLT menu.',
    argument_default  = argparse.SUPPRESS,
    formatter_class   = formatter,
    add_help          = False )

  # required argument
  parser.add_argument('menu',
                      action  = 'store',
                      type    = options.ConnectionHLTMenu,
                      metavar = 'MENU',
                      help    = 'HLT menu to dump from the database. Supported formats are:\n  - /path/to/configuration[/Vn]\n  - [[{v1|v2|v3}/]{run3|run2|online|adg}:]/path/to/configuration[/Vn]\n  - run:runnumber\nThe possible converters are "v1", "v2, and "v3" (default).\nThe possible databases are "run3" (default, used for offline development), "run2" (used for accessing run2 offline development menus), "online" (used to extract online menus within Point 5) and "adg" (used to extract the online menus outside Point 5).\nIf no menu version is specified, the latest one is automatically used.\nIf "run:" is used instead, the HLT menu used for the given run number is looked up and used.\nNote other converters and databases exist as options but they are only for expert/special use.' )

  # options
  parser.add_argument('--dbproxy',
                      dest    = 'proxy',
                      action  = 'store_true',
                      default = defaults.proxy,
                      help    = 'Use a socks proxy to connect outside CERN network (default: False)' )
  parser.add_argument('--dbproxyport',
                      dest    = 'proxy_port',
                      action  = 'store',
                      metavar = 'PROXYPORT',
                      default = defaults.proxy_port,
                      help    = 'Port of the socks proxy (default: 8080)' )
  parser.add_argument('--dbproxyhost',
                      dest    = 'proxy_host',
                      action  = 'store',
                      metavar = 'PROXYHOST',
                      default = defaults.proxy_host,
                      help    = 'Host of the socks proxy (default: "localhost")' )

  parser.add_argument('--prescale-column',
                      dest    = 'prescale_column',
                      action  = 'store',
                      default = '2p0E34',
                      help    = 'Name of main prescale column (default: "2p0E34")' )

  parser.add_argument('--csv-delimiter',
                      dest    = 'csv_delimiter',
                      action  = 'store',
                      default = '|',
                      help    = 'Delimiter used in the .csv output files (default: "|")' )

  parser.add_argument('--metadata-json',
                      dest    = 'metadata_json',
                      action  = 'store',
                      default = 'owners.json',
                      help    = 'Path to .json file with metadata on HLT Paths (online?, group-owners)' )

  parser.add_argument('-o', '--output-dir',
                      dest    = 'output_dir',
                      action  = 'store',
                      default = '.',
                      help    = 'Path to output directory' )

  # redefine "--help" to be the last option, and use a customized message 
  parser.add_argument('-h', '--help', 
                      action  = 'help', 
                      help    = 'Show this help message and exit' )

  # parse command line arguments and options
  config = parser.parse_args()

  process = getHLTProcess(config)

  pathNames = [pathName for pathName, path in process.paths_().items()]

  ## Tab: HLT Prescales
  create_csv(
    outputFilePath = os.path.join(config.output_dir, 'tabHLTPrescales.csv'),
    delimiter = config.csv_delimiter,
    lines = getPrescaleTableLines(process, pathNames),
  )

  ## Tab: HLT Menu
  metadataDict = {}
  if config.metadata_json and os.path.isfile(config.metadata_json):
    metadataDict = json.load(open(config.metadata_json))

  pathAttributes = {}
  for pathName in pathNames:
    pathNameUnv = pathName[:pathName.rfind('_v')+2] if '_v' in pathName else pathName
    pathOwners = ', '.join(metadataDict[pathNameUnv]['owners']) if pathNameUnv in metadataDict else ''
    pathIsOnline = 'Yes' if pathNameUnv in metadataDict and metadataDict[pathNameUnv]['online?'] else 'No'
    pathAttributes[pathName] = {
      'Owners': pathOwners,
      'Online?': pathIsOnline,
      'PS ('+config.prescale_column+')': getPrescale(process, pathName, config.prescale_column),
      'Datasets (SmartPS)': getDatasets(process, pathName),
      'Streams': getStreams(process, pathName),
      'L1T Seed': getL1TSeed(process, pathName),
    }

  linesHLTMenu = [[
    'Path',
    'Owners',
    'Online?',
    'PS ('+config.prescale_column+')',
    'Datasets (SmartPS)',
    'Streams',
    'L1T Seed',
  ]]

  for pathName in pathNames:
    if pathName.startswith('Dataset_'):
      continue
    pathDict = pathAttributes[pathName]
    linesHLTMenu += [[
      pathName,
      pathDict[linesHLTMenu[0][1]],
      pathDict[linesHLTMenu[0][2]],
      pathDict[linesHLTMenu[0][3]],
      pathDict[linesHLTMenu[0][4]],
      pathDict[linesHLTMenu[0][5]],
      pathDict[linesHLTMenu[0][6]],
    ]]

  create_csv(
    outputFilePath = os.path.join(config.output_dir, 'tabHLTMenu.csv'),
    delimiter = config.csv_delimiter,
    lines = linesHLTMenu,
  )

  ## Tab: HLT Datasets and Streams
  dsetDict = getDatasetStreamDict(process)
  linesHLTDatasetsAndStreams = [['Primary Dataset', 'Stream']]
  linesHLTDatasetsAndStreams += [[dset, ', '.join(dsetDict[dset])] for dset in sorted(dsetDict.keys())]
  create_csv(
    outputFilePath = os.path.join(config.output_dir, 'tabHLTDatasetsAndStreams.csv'),
    delimiter = config.csv_delimiter,
    lines = linesHLTDatasetsAndStreams,
  )

###
### main
###
if __name__ == '__main__':
  main()
