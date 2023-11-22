def mac_to_reg_v2(mac_address):
    last_four = mac_address[-4:]
    reversed_hex = [
        hex(int(bin(int(char, 16))[2:].zfill(4)[::-1], 2))[2:] for char in last_four
    ]
    print(reversed_hex)
    register = reversed_hex[0] + reversed_hex[-1]
    return register.upper()


mac_address_example = "02004006e0c2"
register_number_example = mac_to_reg_v2(mac_address_example)
print(register_number_example)
