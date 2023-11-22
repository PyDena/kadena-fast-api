import sys
import re

def bitflipped(bitsin):
    assert re.match(r'^[01]{8}$', bitsin), f"{bitsin} not a byte"
    return bitsin[::-1]

def binify(val):
    val = int(val, 16)
    binexp, bitcount = 1, 0
    while 2 ** bitcount <= val:
        bitcount += 1
    binarray = [int(val / 2 ** i) for i in range(bitcount, -1, -1)]
    for i in range(bitcount + 1):
        if binarray[i]:
            val -= 2 ** i
    val = ''.join(map(str, binarray[::-1]))
    while len(val) < 8:
        val = "0" + val
    if len(val) > 8:
        val = re.sub(r'0*([01]{8})$', r'\1', val)
    return val

def hexify(bin_val):
    assert re.match(r'^([01]{4})([01]{4})$', bin_val)
    hdig = [bin_val[:4], bin_val[4:]]
    for i in range(2):
        over9 = int(hdig[i], 2)
        hdig[i] = format(over9, 'x')
    return ''.join(hdig)

def regmac(reg, site):
    site = site.zfill(4)
    reg = reg.zfill(3)
    return f"40:00:0{site[1]}:{site[2]}{site[3]}:{reg[0]}{reg[1]}:{reg[2]}{site[0]}"

def decode(mac):
    original_mac = re.sub(r'[^0-9a-f]', '', mac, flags=re.I)
    assert re.match(r'^(4000|0200)', original_mac), "Invalid register LAA"
    if original_mac.startswith('02'):
        octet = [original_mac[i * 2:(i * 2) + 2] for i in range(6)]
        mac = ''.join(hexify(bitflipped(binify(o))) for o in octet)
    match = re.match(r'40000(.{3})(.{3})(.)', mac)
    if match:
        inreg, insiteid = match.groups()[1], match.groups()[2] + match.groups()[0]
        inreg, insiteid = inreg.lstrip('0'), insiteid.lstrip('0')
        print(f"MAC: {original_mac}; REG: {inreg}; Site: {insiteid}")
    else:
        print("Canonical match failed.")

def main():
    if len(sys.argv) < 3:
        print("USAGE:\nreg <register #> <store #>\nreg -d <MACaddress>")
        sys.exit(1)
    reg, siteid = sys.argv[1], sys.argv[2]
    if reg == "-d":
        decode(siteid)
    else:
        if not re.match(r'\d{1,3}', reg) or not re.match(r'\d{1,4}', siteid):
            print("Invalid register or Site ID")
            sys.exit(1)
        canon = regmac(reg, siteid)
        noncanon = ''.join(hexify(bitflipped(binify(o))) for o in canon.split(':'))
        canon = canon.replace(':', '')
        print(f"\nRegister {reg} at Site {siteid}:\n    Canonical MAC: {canon}\nNon-Canonical MAC: {noncanon}\n")

if __name__ == "__main__":
    main()
