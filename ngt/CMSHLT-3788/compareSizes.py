#!/usr/bin/env python3

import sys

def parse_file(fname):
    data = {}
    with open(fname) as f:
        for line in f:
            line=line.strip()
            if not line or line.startswith("Branch") or line.startswith("File"):
                continue

            parts=line.split()
            if len(parts) < 3:
                continue

            branch = parts[0]
            uncompressed = float(parts[1])
            compressed = float(parts[2])

            data[branch] = (uncompressed, compressed)

    return data


def main(file1, file2):

    d1 = parse_file(file1)
    d2 = parse_file(file2)

    all_branches = sorted(set(d1) | set(d2))

    print(f"{'Branch':80} {'DeltaUncompressed':>15} {'DeltaCompressed':>15}")
    print("-"*115)

    for b in all_branches:

        u1,c1 = d1.get(b,(0,0))
        u2,c2 = d2.get(b,(0,0))

        du = u2-u1
        dc = c2-c1

        if b in d1 and b in d2:
            print(f"{b:80} {du:15.2f} {dc:15.2f}")

    print("\nBranches only in file1:")
    for b in sorted(set(d1)-set(d2)):
        print(" ",b)

    print("\nBranches only in file2:")
    for b in sorted(set(d2)-set(d1)):
        print(" ",b)


if __name__ == "__main__":
    if len(sys.argv)!=3:
        print("usage: compareEventSize.py file1.txt file2.txt")
        sys.exit(1)

    main(sys.argv[1],sys.argv[2])

