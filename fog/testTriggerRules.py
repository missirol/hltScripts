#!/usr/bin/env python3
from collections import deque, defaultdict
import json
import subprocess
import tempfile

# https://github.com/cms-sw/cmssw/blob/d376eb350a3e9af9f0ce3618fbac6afc36ce56d8/L1Trigger/L1TGlobal/src/GlobalBoard.cc#L1241
def accept(trigger_data):
    prescale_count = round(trigger_data[1] * 100)
    trigger_data[2] += 100
    if prescale_count == 0 or trigger_data[2] < prescale_count:
        return False
    trigger_data[2] -= prescale_count
    return True

def update_l1a_counters(counters, data, rules):
    assert len(counters) == 3565

    # Build list of BCIDs with L1A pre-deadtime
    # (i.e. before Trigger Rules)
    trigger_accepted_BCIDs = set()
    for trigger_name in data:
        trigger_data = data[trigger_name]
        for bcID in trigger_data[0]:
            if accept(trigger_data):
                trigger_accepted_BCIDs.add(bcID)
    raw_l1a = sorted(trigger_accepted_BCIDs)

    # Apply Trigger Rules
    windows = [deque() for _ in rules]

    final_l1a = []

    # Stats
    total_candidates = len(raw_l1a)
    rejected_total = 0
    rejection_per_rule = [0 for _ in rules]

    for bx in raw_l1a:
        violated_rules = []

        for i, (window, max_count) in enumerate(rules):
            dq = windows[i]

            # Drop old BXs outside window
            while dq and bx - dq[0] >= window:
                dq.popleft()

            if len(dq) >= max_count:
                violated_rules.append(i)

        if violated_rules:
            rejected_total += 1
            for i in violated_rules:
                rejection_per_rule[i] += 1
            continue

        final_l1a.append(bx)
        for dq in windows:
            dq.append(bx)

    stats = {
        "total": total_candidates,
        "accepted": len(final_l1a),
        "rejected": rejected_total,
        "rejection_per_rule": {
            f"{rules[i][1]}_in_{rules[i][0]}": rejection_per_rule[i]
            for i in range(len(rules))
        }
    }

    return {
        "final_l1a": final_l1a,
        "stats": stats,
    }


def get_collidingBCIDs_from_filling_scheme(fillingSchemeFile_url):
    try:
        with tempfile.NamedTemporaryFile() as tmp:
            subprocess.run(
                f'wget {fillingSchemeFile_url} -O {tmp.name}'.split(),
                stdout = subprocess.DEVNULL,
                stderr = subprocess.STDOUT
            )
            fs_data = json.load(open(tmp.name))
            return [((foo - 1)//10 + 1) for foo in fs_data["collsIP1/5"]]
    except Exception as ex:
        raise SystemExit(f'\n>>> Fatal Error: failed to obtain the list of colliding BCIDs from\n    {fillingSchemeFile_url}\n\n{ex}')

if __name__ == "__main__":

    num_orbits = 11245

    bcIDs_colliding = get_collidingBCIDs_from_filling_scheme(
        'https://gitlab.cern.ch/lhc-injection-scheme/injection-schemes/-/raw/d5a924dbfa6d5b6fba02e861a9dfc5321e296cf5/25ns_444b_401_364_432_72bpi_9inj_800ns_bs200ns.json'
    )

    bcIDs_gated = [162, 167, 172, 185, 396, 427, 1044, 1278, 1321, 1938, 2172, 2215, 2832]

    trigger_data = {
        # L1T algorithm: (triggered BXs, prescale, prescale counter)
        'L1_BptxOR': [bcIDs_gated, 1.49, 0],
        'L1_ZeroBias': [bcIDs_colliding, 4513, 0],
        'L1_ZeroBias_copy': [bcIDs_colliding, 431, 0],
    }

    trigger_rules = [
        # (B,T): no more than T L1As in B consecutive bunch crossings
        (3, 1),
        (25, 2),
        (100, 3),
        (240, 4),
    ]

    l1a_counters = [0] * 3565

    total, rejected = 0, 0

    for orbit_i in range(num_orbits):
        ret = update_l1a_counters(l1a_counters, trigger_data, trigger_rules)

        total += ret['stats']['total']
        rejected += ret['stats']['rejected']

        for bcID in ret['final_l1a']:
            l1a_counters[bcID] += 1

    print('-'*50)
    print(f'Trigger-Rules Beam-Active Deadtime: {100. * rejected / total:.2f}%')
    print('-'*50)

    for bcID in bcIDs_gated:
        print(f'{bcID:>10d} {l1a_counters[bcID]:>15d}')
