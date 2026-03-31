#!/usr/bin/env python3

B_TO_KB = 1/1024

import sys

def parse_file(fname):
    data = {}
    with open(fname) as f:
        for line in f:
            line = line.strip()

            if not line or line.startswith("Branch") or line.startswith("File"):
                continue

            parts = line.split()
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

    all_branches = set(d1) | set(d2)

    rows = []

    for b in all_branches:

        u1, c1 = d1.get(b, (0.0, 0.0))
        u2, c2 = d2.get(b, (0.0, 0.0))

        du = u2 - u1
        dc = c2 - c1

        rows.append((b, du, dc, b in d1, b in d2))

    # sort by largest compressed change
    rows.sort(key=lambda x: abs(x[2]), reverse=True)

    print()
    print(f"{'Branch':80} {'Delta Uncomp (kB/Event)':>20} {'Delta Comp (kB/Event)':>20}")
    print("-"*130)

    for b, du, dc, in1, in2 in rows:

        if in1 and in2:
            status = ""
        elif in1:
            status = " (removed)"
        else:
            status = " (added)"

        du_kb = du * B_TO_KB
        dc_kb = dc * B_TO_KB
    
        print(f"{b:80} {du_kb:20.2f} {dc_kb:20.2f}{status}")

    # summary
    total_u = sum(r[1] for r in rows) * B_TO_KB
    total_c = sum(r[2] for r in rows) * B_TO_KB

    print("\nSummary:")
    print(f"Total DeltaUncompressed: {total_u:.2f} kB/Event")
    print(f"Total DeltaCompressed:   {total_c:.2f} kB/Event")


if __name__ == "__main__":

    if len(sys.argv) != 3:
        print("Usage: compareEventSize.py file1.txt file2.txt")
        sys.exit(1)

    main(sys.argv[1], sys.argv[2])
