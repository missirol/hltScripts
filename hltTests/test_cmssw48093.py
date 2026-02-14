#!/usr/bin/env python3

def show(setBit12: bool) -> None:
    kShift1 = 9   # erBits
    kShift2 = 12  # miscBits

    kMask1 = 0x000e  # erBits
    kMask2 = 0x000f  # miscBits

    data = 0

    # set bits 9, 10 and 15 (the 10th, 11th, and 16th)
    data |= (1 << 9)
    data |= (1 << 10)
    data |= (1 << 15)

    # set bit 12 (the 13th) if requested
    if setBit12:
        data |= (1 << 12)

    var1 = (data >> kShift1) & kMask1
    var2 = (data >> kShift2) & kMask2

    print(f"bit#12 set to {setBit12}")
    print(f"var1 = {var1:04b} ({var1})")
    print(f"var2 = {var2:04b} ({var2})")
    print("--------------------------")

def main():
    show(True)
    show(False)

if __name__ == "__main__":
    main()
