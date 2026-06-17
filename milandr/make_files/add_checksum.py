import sys
import intelhex

def calculate_checksum(hex_data):
    checksum = sum(hex_data) & 0xFFFF
    return checksum

def main(hex_file, checksum_address):
    try:
        ih = intelhex.IntelHex(hex_file)
        hex_data = ih.tobinarray()
        checksum = calculate_checksum(hex_data)

        # Проверка, что адрес находится в допустимом диапазоне
        if checksum_address < 0 or checksum_address > 0xFFFFFFFF:
            raise ValueError(f"Checksum address {checksum_address} is out of range")

        # Проверка, что контрольная сумма находится в допустимом диапазоне
        if checksum < 0 or checksum > 0xFFFF:
            raise ValueError(f"Checksum {checksum} is out of range")

        # Запись контрольной суммы в HEX-файл
        ih[checksum_address] = checksum & 0xFF
        ih[checksum_address + 1] = (checksum >> 8) & 0xFF

        # Сохранение изменений в HEX-файл
        ih.write_hex_file(hex_file)
        print(f"Checksum {checksum:04X} written to address {checksum_address:08X}")
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python add_checksum.py <hex_file> <checksum_address>")
        sys.exit(1)

    hex_file = sys.argv[1]
    try:
        checksum_address = int(sys.argv[2], 16)
    except ValueError:
        print("Checksum address must be a hexadecimal number")
        sys.exit(1)

    main(hex_file, checksum_address)
