                               _      
                              | |     
 _ __   __ _   _ __   ___   __| | ___ 
| '_ \ / _` | | '_ \ / _ \ / _` |/ _ \
| | | | (_| | | | | | (_) | (_| |  __/
|_| |_|\__,_| |_| |_|\___/ \__,_|\___|
                                                  
networked application node
**************************

Builds on JeeLabs software 
-----------------------------------------------
Download the EtherCard, Ports and RF12 library here (insert into Arduino librarys folder):
http://jeelabs.net/projects/cafe/wiki/EtherCard
http://jeelabs.net/projects/cafe/wiki/Ports
http://jeelabs.net/projects/cafe/wiki/RF12
-----------------------------------------------

This repo contains the code to allow RFM12 RF chip to be used in conjunction with the ENC28J60 Ethernet chip. The both use the SPI bus therefore carefull control of slave-select lines is needed.

In these example we assume RFM12 on SS line digital 10
			Ethernet on SS line digital 8
This notation is consistant with JeeNode (on which code is based), The SS pin for the ENC28J60 is defined in ENC28J60.cpp.

Nanode can be used with certian changes, see: http://openenergymonitor.org/emon/node/143
 
