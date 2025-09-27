# Hardware

Contains a Puya `PY32F002AF15` MCU (Cortex M0+, 32kB of flash, 3kB of SRAM), a `AP4890B` audio amplifier chip (1W Class AB, with shutdown), a mystery OTP Voice chip (SOIC8, marking varies, but mine says `LT-N 2407`), a `AT1141` Walkie Talkie chip (no datasheet available).

This is not a VHF set, only UHF. No FM radio either.

RF amplifier transistor seems to be rated for 2W.


## GPIOs

### MCU
These are the pins of the main PY32F002 MCU:

| Chip Pin | Signal Description | Remarks |
| --- | --- | --- |
| A0 | AT1141 SDIO | I2C bus SDA, bitbanged, external 9k pull up |
| A1 | AT1141 SCLK | I2C bus SCL, bitbanged, external 9k pull up |
| PB2 | Rotary encoder bit 4 | |
| PB0 | Rotary encoder bit 1 | |
| PA7 | Rotary encoder bit 8 | |
| PA4 | Rotary encoder bit 2 | |
| PB6 | PTT Key (PY32F0 pulls it up) | Also BOOT0 |
| PA6 | FUN Key (PY32F0 pulls it up) | |
| PA5 | MONITOR Key (PY32F0 pulls it up) | |
| PA13 | OTP Voice chip "Clock" | Also SWD (disabled by the app) |
| PA14 | OTP Voice chip "Data" | Also SWC (disabled by the app) |
| PA3 | UART RX | Goes to the earphone connector |
| PA2 | UART TX | Goes to the earphone connector |

### AT1141 Walkie Talkie chip
Although it's not a 1-to-1 drop-in replacement of similar chips like `RDA1846`, the pinout seems to be identical. I'll be referencing the `RDA1846` QFN32 pin out for the sake of coherency:

| Chip Pin | Signal Description | Remarks |
| --- | --- | --- |
| #2 SCLK | I2C Clock | Goes to the MCU via a 1k resistor |
| #3 SDIO | I2C Data | Goes to the MCU via a 1k resistor |
| #7 MODE | SPI/I2C select, pulled low by 47k | Pull down: selects I2C mode |
| #32 GPIO0 | GPIO0/css? | ? |
| #31 GPIO1 | GPIO1/code? | Used as GPIO, controls the audio amp (1 = enabled, 0 = shutdown) |
| #30 GPIO2 | GPIO2/int? | Used as GPIO, controls the green LED (1 = on, = 0 off) |
| #29 GPIO3 | GPIO3/sdo? | Used as GPIO, controls the Vtransmit rail (red LED reflects the state of this rail as well, 1 = on, 0 = off) |
| #28 GPIO4 | GPIO4/rxon? | Used as GPIO, controls the white LED (1 = 0n, 0 = off) |
| #27 GPIO5 | GPIO5/txon? | ? |
| #26 GPIO6 | GPIO6/sq? | ? |
| #25 GPIO7 | GPIO7/vox? | ? |

# AT1141 register map

AT1141 is located at address 0x71, as what the similar RDA1846 would.
However, not a single register address/value matches the RDA1846.


Registers are 16 bit wide.

| Address | Initial value | Description | Access | Remarks |
| --- | --- | --- | --- | --- |
| [0x2A](#0x2a) | ? | GPIO bank 0 (GPIO0-3) | RW | |
| [0x2B](#0x2b) | ? | GPIO bank 1 (GPIO4-7) | RW | |
| [0x73](#0x73) | ? | Status register? | R (W?) | |

## 0x2B

| Bit | Description | Values |
| --- | --- | --- |
| 15-12 | GPIO7 | `0b1111` = GPIO on, `0b0000` = GPIO off |
| 11-8 | GPIO6 | `0b1111` = GPIO on, `0b0000` = GPIO off |
| 7-4 | GPIO5 | `0b1111` = GPIO on, `0b0000` = GPIO off |
| 3-0 | GPIO4 | `0b1111` = GPIO on, `0b0000` = GPIO off |


## 0x2A

| Bit | Description | Values |
| --- | --- | --- |
| 15-12 | GPIO3 | `0b1111` = GPIO on, `0b0000` = GPIO off |
| 11-8 | GPIO2 | `0b1111` = GPIO on, `0b0000` = GPIO off |
| 7-4 | GPIO1 | `0b1111` = GPIO on, `0b0000` = GPIO off |
| 3-0 | GPIO0 | `0b0001` = GPIO on, `0b0000` = GPIO off |

## 0x73

While receiving I could see a value of `0x0580`, and a value of `0x0300` while not. Firmware checks for bit 7 as an indicator of "receiving".

| Bit | Description | Values |
| --- | --- | --- |
| 7 | Receiving (squelch+css/dcss?) bit | 1 = receiving, 0 = not receiving |

# Firmware
It's trivial to dump the firmware if the MCU starts in its bootloader mode (`BOOT0` set to HIGH) through SWD. See [this](https://github.com/IOsetting/py32f0-template/issues/60#issuecomment-3226084080) comment on how to dump the flash. My firmware seems to have a version of `V.01.07`. All my analysis has been done on that version.

Seems like Baofeng has a bootloader in place, using the first 5kB (0x0000-0x13ff) of flash. There's an "application" loaded right after the bootloader. This application is just a regular Puya PY32F0x binary image, as described below.

## Bootloader
The bootloader is able to update the "application" through the serial port (using the programming cable) via a really simple protocol. In order to enter this mode, the radio needs to be off, channel set as 4 (TBD) and the FUN+MONITOR buttons pressed simultaneously, then turn the radio on. There's no indication that the processor has entered the bootloader mode, other than the fact that it doesn't do anything when pressing the keys.

I haven't tried it yet, but seems to be as simple as just sending 128 bytes chunks of the 26kB binary image at a time, and waiting for a single byte of ACK (0x06) or NACK (which is an error, and the processor "halts", 0x4e). Once the whole 26kB of data is transferred (19200 bps, 1 stop bit, no parity), I think the bootloader just boots it.

## Application
The application binary is located at `0x14000` in the flash (`0x08001400` in the MCU's memory map), containing the VTOR table (Stack Pointer and IRQ handlers). All pointers point to a direction in the MCU's memory address, they're not a *flash offset*!


| Address in flash | Description | Remarks |
| --- | --- | --- |
| 0x1400 | Initial stack pointer | Application-defined position of the initial stack pointer, set to `0x20000710` on firmware `V.01.07` |
| 0x1404 | Reset Handler | Pointer to the entry point of the application |
| 0x1408 | NMI Handler | Non maskable interrupt handler pointer |
| 0x140C | Hard Fault Handler | ARM Hard Fault handler pointer |
| 0x1410-0x1428 | Reserved | ARM Cortex M0+ Reserved |
| 0x142C | SVC Handler | ARM SVC handler pointer |
| 0x1430-0x1434 | Reserved | ARM Cortex M0+ Reserved |
| 0x1438 | PendSV Handler | ARM PendSV handler pointer |
| 0x143C | SysTick Handler | ARM SysTick handler pointer |
| 0x1440-0x1448 | Reserved | ARM Cortex M0+ Reserved |
| 0x144C | Flash IRQ Handler | PY32F0x FLASH peripheral interrupt handler pointer |
| 0x1450 | RCC IRQ Handler | PY32F0x RCC peripheral interrupt handler pointer |
| 0x1454 | EXTI0_1 IRQ Handler | PY32F0x EXTI0_1 peripheral interrupt handler pointer |
| 0x1458 | EXTI2_3 IRQ Handler | PY32F0x EXTI2_3 peripheral interrupt handler pointer |
| 0x145C | EXTI4_15 IRQ Handler | PY32F0x EXTI4_15 peripheral interrupt handler pointer |
| 0x1460 | PY32F0x Reserved | |
| 0x1464 | PY32F0x Reserved | |
| 0x1468 | PY32F0x Reserved | |
| 0x146C | PY32F0x Reserved | |
| 0x1470 | ADC_COMP IRQ Handler | PY32F0x ADC_COMP peripheral interrupt handler pointer |
| 0x1474 | TIM1_BRK_UP_TRG_COM IRQ Handler | PY32F0x TIM1_BRK_UP_TRG_COM peripheral interrupt handler pointer |
| 0x1478 | TIM1_CC IRQ Handler | PY32F0x TIM1_CC peripheral interrupt handler pointer |
| 0x147C | PY32F0x Reserved | |
| 0x1480 | PY32F0x Reserved | |
| 0x1484 | LPTIM1 IRQ Handler | PY32F0x LPTIM1 peripheral interrupt handler pointer |
| 0x1488 | PY32F0x Reserved | |
| 0x148C | PY32F0x Reserved | |
| 0x1490 | PY32F0x Reserved | |
| 0x1494 | TIM16 IRQ Handler | PY32F0x TIM16 peripheral interrupt handler pointer |
| 0x1498 | PY32F0x Reserved | |
| 0x149C | I2C1 IRQ Handler | PY32F0x I2C1 peripheral interrupt handler pointer |
| 0x14A0 | PY32F0x Reserved | |
| 0x14A4 | SPI1 IRQ Handler | PY32F0x SPI1 peripheral interrupt handler pointer |
| 0x14A8 | PY32F0x Reserved | |
| 0x14AC | USART1 IRQ Handler | PY32F0x USART1 peripheral interrupt handler pointer |
| 0x14B0 | PY32F0x Reserved | |
| 0x14B4 | PY32F0x Reserved | |
| 0x14B8 | PY32F0x Reserved | |
| 0x14BC | PY32F0x Reserved | |


### Application's EEPROM

The original firmware uses a portion of the flash as the radio's EEPROM. This is usually the configuration table that can be modified with tools like [CHIRP](https://github.com/kk7ds/chirp).

Located at flash offsets `0x7C00` through `0x7FFF` (`0x08007C00`-`0x08007FFF` on the MCU's memory map), it contains 1kB of data. Comparing a raw dump of CHIRP and the obtained raw dump of the flash, there's a 100% match of this data.

The following table contains a list of offsets from the start of the "EEPROM" and what their values might mean. Most of them were just obtained by looking ath CHIRP's [source code](https://github.com/kk7ds/chirp/blob/master/chirp/drivers/h777.py#L30).

| Offset | Size | Description | Remarks |
| --- | --- | --- | --- |
| 0x0010-0x0100 | 256 | 16x channel structure | |
| 0x02b0 | 1 | Voice Prompt enable (0 = off, 1 = on) | |
| 0x02b1 | 1 | Voice Prompt language (0 = english, 1 = chinese) | |
| 0x02b2 | 1 | Scan enable (0 = off, 1 = on) | |
| 0x02b3 | 1 | VOX enable (0 = off, 1 = on) | |
| 0x02b4 | 1 | VOX level | |
| 0x02b5 | 1 | VOX inhibit on RX (0 = VOX enabled when receiving, 1 = VOX disabled when receiving) | |
| 0x02b6 | 1 | Lower limit of battery voltage for TX inhibit | |
| 0x02b7 | 1 | Upper limit of battery voltage for TX inhibit | |
| 0x02b8 | 1 | Alarm enable (?) | Should not apply to this radio |
| 0x02b9 | 1 | FM Radio |  |
| 0x03c0 | 1 | Bit0 = Beep enable (0 = off, 1 = on), Bit1 = Battery Saver enable (0 = off, 1 = on) | |
| 0x03c1 | 1 | Squelch level (?) | |
| 0x03c2 | 1 | Side-key function (0 = off, 1 = monitor, 2 = toggle transmit power, 3 = alarm) | The toggle transmit power should not apply to this radio |
| 0x03c3 | 1 | Transmit timeout timer in a 30-seconds base (i.e. 0 = 0s, 1 = 30s, 2 = 60s, etc) | |
| 0x03c4-0x0c6 | 1 | Unused | |
| 0x03c7 | 1 | Bit0 = Scan Mode (0 = carrier, 1 = time) | TBD |

# Homebrew Firmware

This is a work-in-progress. Current aim is to be able to flash a custom application replacing Baofeng's stock application (leaving their bootloader in place!).

A new linker script should be created for the hello world homebrew application. The idea for this app is to send some data through the UART, maybe reacting to the PTT, FUN and MONITOR buttons; and/or even reading and writing registers of the AT1141 to further understand how it works.

Please feel free to open PRs or questions as a new issue.
