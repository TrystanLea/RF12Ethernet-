This repo contains the code to allow RFM12 RF chip to be used in conjunction with the ENC28J60 Ethernet chip. The both use the SPI bus therefore carefull control of slave-select lines is needed.

In these example we assume RFM12 on SS line digital 10
			Ethernet on SS line digital 8
This notation is consistant with JeeNode (on which code is based), The SS pin for the ENC28J60 is defined in ENC28J60.cpp.

Nanode can be used with certian changes, see: http://openenergymonitor.org/emon/node/143
 
