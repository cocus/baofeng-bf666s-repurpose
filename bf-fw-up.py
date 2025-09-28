import serial, sys, time

CHUNK = 128
TOTAL = 26624
DELAY = 0.001  # 1 ms per byte

def main(port, filename):
    with open(filename, "rb") as f:
        data = f.read()

    # pad with zeros at the END until length is exactly TOTAL
    if len(data) < TOTAL:
        data += b"\x00" * (TOTAL - len(data))
    else:
        data = data[:TOTAL]

    with serial.Serial(port, 19200, bytesize=8, stopbits=1, parity='N', timeout=2) as ser:
        for i in range(0, TOTAL, CHUNK):
            # send byte by byte with delay
            ser.write(data[i:i+CHUNK])
            #for b in data[i:i+CHUNK]:
            #    ser.write(bytes([b]))
            #    time.sleep(DELAY)

            resp = ser.read(1)
            if not resp:
                print("Timeout at chunk", i // CHUNK)
                sys.exit(1)
            if resp[0] == 0x4E:
                print("Error at chunk", i // CHUNK)
                sys.exit(1)
            if resp[0] != 0x06:
                print("Unexpected response:", resp)
                sys.exit(1)
    print("Transmission complete.")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <port> <input.bin>")
        sys.exit(1)
    main(sys.argv[1], sys.argv[2])
