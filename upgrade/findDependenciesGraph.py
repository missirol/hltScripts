
# Usage:
# Save the following file as test.py
# then edmConfigDump.py test.py > dump.py
# and then copy the lines that end of the script in dump.py and the python3 dump.py

# import FWCore.ParameterSet.Config as cms
# from Configuration.ProcessModifiers.phase2CAExtension_cff import phase2CAExtension
# from Configuration.ProcessModifiers.ngtScouting_cff import ngtScouting
# process = cms.Process("HLT", phase2CAExtension, ngtScouting)
# process.load("HLTrigger.Configuration.HLT_NGTScouting_cff")

#for name in sorted(set(
#        list(process.producers_().keys()) +
#        list(process.filters_().keys()) +
#        list(process.analyzers_().keys()) +
#        list(process.outputModules_().keys()))):
#    if "hltGeneralTracks" in getattr(process, name).dumpPython():
#        print(name)


# targets = [
#     "hltGeneralTracks",
#     "hltEgammaEleGsfTrackIsoL1Seeded",
#     "hltEgammaEleGsfTrackIsoUnseeded",
#     "hltEgammaHollowTrackIsoL1Seeded",
#     "hltEgammaHollowTrackIsoUnseeded",
#     "hltPfTrack",
#     "hltTiclCandidate",
#     "hltTiclTrackstersMerge",
#     "hltTrackWithVertexRefSelectorBeforeSorting",
#     "hltUnsortedOfflinePrimaryVertices",
#     "hltDiEle2312IsoGsfTrackIsoL1SeededFilter",  
#     "hltEle26WP70GsfTrackIsoL1SeededFilter",     
#     "hltEle26WP70GsfTrackIsoUnseededFilter",     
#     "hltEle32WPTightGsfTrackIsoL1SeededFilter",  
#     "hltEle32WPTightGsfTrackIsoUnseededFilter",  
#     "hltEle5WPTightGsfTrackIsoL1SeededFilter",  
#     "hltEle5WPTightGsfTrackIsoUnseededFilter",  
#     "hltOfflinePrimaryVertices",                 
#     "hltParticleFlowBlock",                      
#     "hltParticleFlowClusterHGCal",               
#     "hltPfTICL",                                 
#     "hltTrackRefsForJetsBeforeSorting",       
#     "hltTrackWithVertexRefSelectorBeforeSorting"
# ]

# all_modules = sorted(set(
#     list(process.producers_().keys()) +
#     list(process.filters_().keys()) +
#     list(process.analyzers_().keys()) +
#     list(process.outputModules_().keys())
# ))

# print("Modules consuming requested products:\n")
# for name in all_modules:
#     dump = getattr(process, name).dumpPython()
#     used = [t for t in targets if t in dump]
#     if used:
#         print(f"{name}  <-- uses: {', '.join(used)}")


import FWCore.ParameterSet.Config as cms
from collections import defaultdict

SEED = "hltGeneralTracks"

def extract_module_label(x):
    """Return module label if x is InputTag-like, else None"""
    if isinstance(x, cms.InputTag):
        return x.getModuleLabel()

    if isinstance(x, str):
        # string InputTag form: "module[:product[:process]]"
        return x.split(":")[0]

    return None


def iter_inputtags(obj):
    """Yield module labels of all InputTags inside obj"""
    if isinstance(obj, cms.InputTag) or isinstance(obj, str):
        label = extract_module_label(obj)
        if label:
            yield label

    elif isinstance(obj,
                  (cms.PSet, cms.EDProducer, cms.EDFilter,
                   cms.EDAnalyzer, cms.Service)):
        for _, v in obj.parameters_().items():
            yield from iter_inputtags(v)

    elif isinstance(obj, cms.VPSet):
        for p in obj:
            yield from iter_inputtags(p)

    elif isinstance(obj, cms.VInputTag):
        for tag in obj:
            yield from iter_inputtags(tag)


def allModuleNames(process):
    names = set()
    names.update(process.producers_().keys())
    names.update(process.filters_().keys())
    names.update(process.analyzers_().keys())
    names.update(process.outputModules_().keys())
    return sorted(names)


modules = {name: getattr(process, name) for name in allModuleNames(process)}

consumers = defaultdict(set)

for name, mod in modules.items():
    for label in iter_inputtags(mod):
        if label in modules:
            consumers[label].add(name)

print("Consumer graph built.")

levels = []
seen = set()
current = {SEED}

while current:
    levels.append(current)
    seen |= current
    nxt = set()
    for m in current:
        nxt |= consumers.get(m, set())
    nxt -= seen
    current = nxt


print(f"\n=== Dependency levels starting from {SEED} ===\n")
for i, lvl in enumerate(levels):
    print(f"Level {i}:")
    for m in sorted(lvl):
        print("   ", m)
    print()

dot_lines = [
    "digraph HLTDeps {",
    "rankdir=LR;",
    "node [shape=box, fontsize=10];"
]

for src, dsts in consumers.items():
    for dst in dsts:
        if src in seen or dst in seen:
            dot_lines.append(f'"{src}" -> "{dst}";')

dot_lines.append("}")

with open("hltGeneralTracks_graph.dot", "w") as f:
    f.write("\n".join(dot_lines))

print("Wrote hltGeneralTracks_graph.dot")
print("Render with: dot -Tpdf hltGeneralTracks_graph.dot -o hltGeneralTracks_graph.pdf")
