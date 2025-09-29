import serial
import math
import sys
import time
import tqdm  # pip install tqdm

BLOCK_SIZE = 128
MAX_SIZE = 26624  # 26 KB = 208 × 128

def send_firmware(port, firmware_path):
    ser = serial.Serial(
        port=port,
        baudrate=9600,
        bytesize=serial.EIGHTBITS,
        stopbits=serial.STOPBITS_ONE,
        parity=serial.PARITY_NONE,
        timeout=3
    )

    # --- Load firmware ---
    with open(firmware_path, "rb") as f:
        fw = f.read()

    fw_size = len(fw)
    print(f"[*] Firmware size: {fw_size} bytes")

    if fw_size > MAX_SIZE:
        raise ValueError(f"Firmware too big ({fw_size} > {MAX_SIZE})")

    # --- Round up to multiple of 128 ---
    num_blocks = math.ceil(fw_size / BLOCK_SIZE)
    padded_fw = fw.ljust(num_blocks * BLOCK_SIZE, b"\x00")
    has_end_marker = False

    # --- If size <= 26624 - 128, append special 0x45 block ---
    if fw_size <= (MAX_SIZE - BLOCK_SIZE):
        print("[*] Size is less than available flash, end block will be sent")
        has_end_marker = True

    print(f"[*] Total blocks to send: {num_blocks}, {len(padded_fw)} bytes")

    # --- Send blocks with progress bar ---
    block_index = 0
    with tqdm.tqdm(total=num_blocks, unit="block") as pbar:
        while block_index < num_blocks:
            block = padded_fw[block_index*BLOCK_SIZE:(block_index+1)*BLOCK_SIZE]

            # Transmit block slowly
            ser.write(block)
            #for b in block:
            #    ser.write(bytes([b]))

            #time.sleep(1) # takes around 1.3s to reply
            if block_index == 0:
                time.sleep(2) # additional 8s

            # Wait for response
            resp = ser.read(1)
            if not resp:
                raise TimeoutError(f"No response after block {block_index}")
            elif resp == b'\x06':  # ACK
                block_index += 1
                pbar.update(1)
                #time.sleep(7.8) # if you go lower than this, it just stops replying. probably some flash write timing is play here
                continue
            elif resp == b'N':  # NACK, MCU will reset the procedure (I think)
                print(f"[!] NACK on block {block_index+1}, restarting...")
                block_index = 0
                ser.reset_input_buffer()
                ser.reset_output_buffer()
                time.sleep(0.5)
                pbar.reset()
                continue
            else:
                raise RuntimeError(f"Unexpected response: {resp.hex()}")

    if has_end_marker:
        # --- Send final 'E' block ---
        end_block = bytes([ord('E')]) + b"\x00" * (BLOCK_SIZE - 1)
        #for b in end_block:
        #    ser.write(bytes([b]))
        print("[*] Sent final 'E' block. Bootloader should now halt.")

    ser.close()


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <port> <firmware.bin>")
        sys.exit(1)

    port = sys.argv[1]
    firmware = sys.argv[2]

    send_firmware(port, firmware)
