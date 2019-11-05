# RasPi_SupercapUPS
Expansion board with UPS using supercaps and a special wadchdog/undervoltage detection

## Motivation
I am running a Raspberry Pi in a holiday home. This device also  controls the heating of the water pipes in winter, so it is "mission critical". It also allows to remotly switch on the room heating via sms text messages. Regular status messages are also provided via sms. These functions have been implemented using the smart-home suite iobroker (https://www.iobroker.net/)
Since the electricity grid is sometimes unreliable, a kind of power buffer is needed to have enough time to shut down everything in case of a power loss. Since I do not want to use the usual lithium ion battery based UPS available on the market; I was looking for an alternative and found this: https://www.hackerspace-ffm.de/wiki/index.php?title=Raspi_EDLC_UPS.
The supercaps provide enough energy to supply the raspi for 20 - 30 s which is enough for a safe shutdown. The status of the power supply is provided to one of the GPIO pins of the raspi. The status of this pin is monitored by an iobroker function and a system shutdown command is initiated if a power loss is detected.

## Requirements
- provide enough energy for a safe shutdown of the raspberry pi
- provide a power loss signal
- provide an undervoltage / power good signal to trigger a reboot after power loss
- provide a watchdog to avoid a system hangup (e.g. in case of a short power loss when undervoltage conditions are not yet met)
## Optional requirements
- provide a relay output to control room heating
- measure the actual raspberry pi supply voltage provided by the supercaps
- provide a socket for an I2C real-time clock module
## Implementation
The device is implemented as an accessory pcb to be mounted on top of the raspberry. It consists of the energy storage block and a watchdog block. Furthermore, I have added a relay to be able to switch on the electrical room heating from remote via a sms text message.
### Energy Buffer
The energy buffer consists of 2x 50F supercaps in series with a charge balancer circuit and a charge current limiting resistor. The capacitor bank is decoupled with Schottky diodes from the external power supply. Therefore, the power supply needs to provide a slightly higher voltage, e.g. 5.5V in order to obtain a 5 V supply voltage at the raspi.
### Watchdog and undervoltage detection
Since I could not find a watchdog IC combining a (programmable) watchdog dead time of 2 min ith a precise undervoltage detector, I have implemented this function using an Atmel ATTINY85 microcontroller. Even though this controller has enough memory so that the functionality could be implemented using the Arduino programming environment, I decided that I wanted to learn something new - so the functionality has been implemented in Assembler.
Since the Raspi provides an SPI interface, the ATTINY can be directly programmed using avrdude.
### Relay stage
This is straightforward: a Darlington (overdimensioned, but this was the one I had in my stock) connected to GPIO27 controls the relay. 
### Miscellaneous
Connector blocks are provided to hook up an external indicator LED for the relay and a voltmeter module to measure the raspberry pi supply voltage. Furthermore, a real-time clock module can be connected via a 4 pin header in vertical position.
## Hardware
KiCad schematics and pcb layout is provided in the hardware directory; Gerber and drill files can be found in the CAM subdirectory.
## Software
I used VSCode and PlatformIO as development environment. 
