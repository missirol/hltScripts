#!/usr/bin/env python3
"""
printTFile.py
 
Recursively print the entire content of a ROOT TFile to stdout in a
deterministic, human-readable text format. Intended use: print two
files that are supposed to be identical, then `diff` the two text
outputs.
 
    python printTFile.py fileA.root > fileA.txt
    python printTFile.py fileB.root > fileB.txt
    diff fileA.txt fileB.txt
 
Handles, recursively:
  - TDirectory / nested TDirectory (sub-folders inside the file)
  - TTree: printed entry-by-entry, branch-by-branch (works for scalar
    branches and for vector/array-like branches, e.g. std::vector<T>)
  - TH1-derived histograms: printed bin-by-bin (content + error),
    including under/overflow bins
  - Anything else: falls back to ClassName() + str(obj). This is a
    best-effort fallback (e.g. TObjString, TParameter<T> print fine;
    more exotic custom classes may need a dedicated print function -
    see print_object_generic()).
 
Notes on determinism:
  - Keys are sorted alphabetically before being visited, so the
    output order does not depend on the physical key order in the
    file (which can vary even for "identical" content).
  - Only the highest cycle of each key is read (TDirectory::GetKey
    returns the highest cycle by default), so re-written/duplicated
    keys don't produce spurious diffs.
  - Floats are formatted with fixed precision (%.9g) for stable,
    comparable text output.

Original author: Claude Sonnet 4.6
"""
import sys
import ROOT

ROOT.gROOT.SetBatch(True)

def fmt_value(val):
    """Convert a branch value (scalar, vector, array, ...) into a stable string."""
    try:
        if hasattr(val, "__len__") and not isinstance(val, (str, bytes)):
            return "[" + ", ".join(fmt_value(v) for v in val) + "]"
    except Exception:
        pass
    if isinstance(val, float):
        return "%.9g" % val
    return str(val)

def print_tree(tree, path, max_tree_entries):
    branch_names = sorted(b.GetName() for b in tree.GetListOfBranches())
    n = tree.GetEntries()
    print(f"### TTree {path} | entries={n} | branches={branch_names}")
    for i, entry in enumerate(tree):
        if i > max_tree_entries:
            continue
        fields = []
        for bname in branch_names:
            try:
                val = getattr(entry, bname)
            except Exception:
                val = "<UNREADABLE>"
            fields.append(f"{bname}={fmt_value(val)}")
        print(f"{path}[{i}]: " + " | ".join(fields))

def print_histogram(hist, path):
    print(
        f"### {hist.ClassName()} {path} | entries={hist.GetEntries()} "
        f"| mean={hist.GetMean():.9g} | rms={hist.GetRMS():.9g}"
    )
    nbins = hist.GetNbinsX()
    for b in range(0, nbins + 2):  # include underflow (0) and overflow (nbins+1)
        c = hist.GetBinContent(b)
        e = hist.GetBinError(b)
        print(f"{path}.bin[{b}]: content={c:.9g} error={e:.9g}")

def print_object_generic(obj, path):
    print(f"### {obj.ClassName()} {path} | str={str(obj)}")

def walk(directory, path, max_tree_entries):
    keys = directory.GetListOfKeys()
    names = sorted(set(k.GetName() for k in keys))
    for name in names:
        key = directory.GetKey(name)
        obj = key.ReadObj()
        if obj.InheritsFrom("TDirectory"):
            print(f"### TDirectory {name}")
            walk(obj, name, max_tree_entries)
        elif obj.InheritsFrom("TTree"):
            print_tree(obj, name, max_tree_entries)
        elif obj.InheritsFrom("TH1"):
            print_histogram(obj, name)
        else:
            print_object_generic(obj, name)

def main():
    if len(sys.argv) != 2:
        sys.stderr.write(f"Usage: {sys.argv[0]} <file.root>\n")
        sys.exit(1)

    fname = sys.argv[1]
    f = ROOT.TFile.Open(fname, "READ")
    if not f or f.IsZombie():
        sys.stderr.write(f"Error: could not open {fname}\n")
        sys.exit(1)

    print(f"### TFile {fname}")
    walk(f, fname, 100)
    f.Close()

if __name__ == "__main__":
    main()
