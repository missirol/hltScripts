import FWCore.ParameterSet.Config as cms

def getModuleParameters(module):
    ret = module.parameters_()
    return ret

def areIdenticalModuleParameters(params1, params2):
    return str(params1) == str(params2)

def getNewEleWPTightParams(cutType, module):
    params = getModuleParameters(module)

    if cutType == 'NameWPTight':
        pass

    elif cutType == 'ClusterShape':

        if module.type_() == 'HLTEgammaGenericFilter' and \
            module.varTag.getProductInstanceLabel() == 'sigmaIEtaIEta5x5NoiseCleaned' and \
            params['thrRegularEB'].value() == [0.011]:
            params['thrRegularEB'] = [0.0105]

    elif cutType == 'HE':

        if module.type_() == 'HLTEgammaGenericQuadraticEtaFilter' and \
           'HoverE' in module.varTag.getModuleLabel() and \
           params['thrRegularEB1'].value() == [0.75] and \
           params['thrOverEEB1'].value() == [0.03] and \
           params['thrRegularEB2'].value() == [2.25] and \
           params['thrOverEEB2'].value() == [0.03] and \
           params['effectiveAreas'].value()[0] == 0.1 and \
           params['effectiveAreas'].value()[0] == 0.1:
            params['thrRegularEB1'] = [1.0]
            params['thrOverEEB1'] = [0.06]
            params['thrRegularEB2'] = [1.0]
            params['thrOverEEB2'] = [0.06]
            params['effectiveAreas'][0] = 0.066
            params['effectiveAreas'][1] = 0.14

    elif cutType == 'PFClusterIso':

        if module.type_() == 'EgammaHLTEcalPFClusterIsolationProducer' and \
           params['drMax'].value() == 0.3 and \
           params['effectiveAreas'].value() == [0.29, 0.21]:
            params['drMax'] = 0.2
            params['effectiveAreas'] = [0.085, 0.0]

    elif cutType == 'EcalIso':

        if module.type_() == 'HLTEgammaGenericQuadraticEtaFilter' and \
           'Ecal' in module.varTag.getModuleLabel() and \
           'Iso' in module.varTag.getModuleLabel() and \
           params['thrRegularEB1'].value() == [1.75] and \
           params['thrOverEEB1'].value() == [0.03] and \
           params['thrRegularEB2'].value() == [1.75] and \
           params['thrOverEEB2'].value() == [0.03] and \
           params['effectiveAreas'].value() == [0.2, 0.2, 0.25, 0.3]:
            params['thrRegularEB1'] = [3.0]
            params['thrOverEEB1'] = [0.01]
            params['thrRegularEB2'] = [3.0]
            params['thrOverEEB2'] = [0.01]
            params['effectiveAreas'] = [0.1, 0.08, 0.06, 0.06]

    elif cutType == 'HcalIso':

        if module.type_() == 'HLTEgammaGenericQuadraticEtaFilter' and \
           'Hcal' in module.varTag.getModuleLabel() and \
           'Iso' in module.varTag.getModuleLabel() and \
           params['thrRegularEB1'].value() == [2.5] and \
           params['thrOverEEB1'].value() == [0.03] and \
           params['thrRegularEB2'].value() == [3.0] and \
           params['thrOverEEB2'].value() == [0.03] and \
           params['effectiveAreas'].value()[0] == 0.2 and \
           params['effectiveAreas'].value()[1] == 0.2:
            params['thrRegularEB1'] = [4]
            params['thrOverEEB1'] = [0.04]
            params['thrRegularEB2'] = [4]
            params['thrOverEEB2'] = [0.04]
            params['effectiveAreas'][0] = 0.26
            params['effectiveAreas'][1] = 0.32

    elif cutType == 'TrackIso':

        if module.type_() == 'HLTEgammaGenericQuadraticEtaFilter' and \
           'TrackIso' in module.varTag.getModuleLabel() and \
           params['thrRegularEB1'].value() == [0.838] and \
           params['thrOverEEB1'].value() == [0.03] and \
           params['thrRegularEB2'].value() == [-0.385] and \
           params['thrOverEEB2'].value() == [0.03] and \
           params['effectiveAreas'].value()[0] == 0.029 and \
           params['effectiveAreas'].value()[1] == 0.111:
            params['thrRegularEB1'] = [2.0]
            params['thrOverEEB1'] = [0.0]
            params['thrRegularEB2'] = [2.0]
            params['thrOverEEB2'] = [0.0]
            params['effectiveAreas'][0] = 0.03
            params['effectiveAreas'][1] = 0.04

    elif cutType == 'PMS2':

        if module.type_() == 'HLTEgammaGenericFilter' and \
           module.varTag.getProductInstanceLabel() == 's2' and \
           params['thrRegularEB'].value() == [70]:
            params['thrRegularEB'] = [200]

    elif cutType == '1E1p':

        if module.type_() == 'HLTEgammaGenericFilter' and \
           module.varTag.getProductInstanceLabel() == 'OneOESuperMinusOneOP' and \
           params['thrRegularEB'].value() == [0.012]:
            params['thrRegularEB'] = [0.025]

    elif cutType == 'Deta':

        if module.type_() == 'HLTEgammaGenericFilter' and \
           module.varTag.getProductInstanceLabel() == 'DetaSeed' and \
           params['thrRegularEB'].value() == [0.004]:
            params['thrRegularEB'] = [0.003]

    elif cutType == 'Dphi':

        if module.type_() == 'HLTEgammaGenericFilter' and \
           module.varTag.getProductInstanceLabel() == 'Dphi' and \
           params['thrRegularEB'].value() == [0.02]:
            params['thrRegularEB'] = [0.03]

    else:
        raise RuntimeError(f'changeWPTightCut -- undefined cut type: {cutType}')

    return params

def printInfoOnEleWPTightRetuning(process):
    process = customizeHLTforEleWPTightRetuning(process, updateModules=False)
    return process

def customizeHLTforEleWPTightRetuning(process, updateModules=True):

    flagTypes = [
      'NameWPTight',
      'ClusterShape',
      'HE',
      'PFClusterIso',
      'EcalIso',
      'HcalIso',
      'TrackIso',
      'PMS2',
      '1E1p',
      'Deta',
      'Dphi',
    ]

    headerLine = f'{"Path":<95}'
    for headerEntry in flagTypes:
        headerLine += f' {headerEntry:<12}'
    printoutLines = [headerLine]

    for pathName in process.paths_():
        path = getattr(process, pathName)

        flags = {}
        for flagType in flagTypes:
            flags[flagType] = 0

        flags['NameWPTight'] = int('_WPTight_Gsf' in pathName)

        moduleNames = []
        for (type_i, label_i) in path.expandAndClone().directDependencies():
            if type_i != 'modules': continue
            moduleNames += [label_i]
        moduleNames = sorted(list(set(moduleNames)))

        for moduleName in moduleNames:
            module = getattr(process, moduleName)
            moduleParamsOld = getModuleParameters(module)
            for cutType in flags:
                moduleParamsNew = getNewEleWPTightParams(cutType, module)
                if not areIdenticalModuleParameters(moduleParamsOld, moduleParamsNew):
                    if updateModules:
                        module.update_(moduleParamsNew)
                    moduleParamsOld = getModuleParameters(module)
                    flags[cutType] += 1
                    break

        printLine = any([flags[foo] for foo in flags])
        if printLine:
            outLine = f'{pathName:<95}'
            for flagType in flagTypes:
                printValue = flags[flagType] if flags[flagType] else ''
                outLine += f' {printValue:<12}'
            printoutLines += [outLine]

    for printoutLine in printoutLines:
        print(printoutLine)

    return process
