//--------------------------------------------------------------------------------------
//Test Sketch to transmitt dummy data to test RFM12 
//For running on JeeNode hardware 

//Based on JeeLabs RF12 library http://jeelabs.org/2009/02/10/rfm12b-library-for-arduino/

// Hope TRX433S/ Alpha RF12 
// http://www.quasaruk.co.uk/acatalog/DSQ-ALPHA-TRX-2.pdf
// http://www.hoperf.com/upfile/RF12.pdf

// By Glyn Hudson 30/4/11
// openenergymonitor.org
// GNU V3
//--------------------------------------------------------------------------------------

//JeeNodes librarys 
#include <Ports.h>
#include <RF12.h>
#include <avr/eeprom.h>
#include <util/crc16.h>  //cyclic redundancy check


// fixed RF12 settings
#define myNodeID     5//node 5
#define network     212  //212 network
#define freq RF12_433MHZ

#define RETRY_LIMIT     1  // maximum number of times to retry   - ACK CURRENTY NOT WORKING!!!
#define ACK_TIME        10  // number of milliseconds to wait for an ack

// set the sync mode to 2 if the fuses are still the Arduino default
// mode 3 (full powerdown) can only be used with 258 CK startup fuses
#define RADIO_SYNC_MODE 2


const int RFled=9;     //RF indicator LED

#define COLLECT 0x20 // collect mode, i.e. pass incoming without sending acks

//data structure to be sent. Must be same on the receiver 
typedef struct {
  int temp;
  int power;
} Payload;
Payload measurement;


typedef struct {
  byte nodeId;
  byte group;
  byte band;
  char msg[RF12_EEPROM_SIZE-4];
  word crc;
} 
RF12Config;

static RF12Config config;

static void addCh (char* msg, char c) {
  byte n = strlen(msg);
  msg[n] = c;
}

static void addInt (char* msg, word v) {
  if (v >= 10)
    addInt(msg, v / 10);
  addCh(msg, '0' + v % 10);
}




//********************************************************************
//SETUP
//********************************************************************
void setup() {
  Serial.begin(9600);
  Serial.println("RMF12 simple node demo");

  pinMode(RFled, OUTPUT);

  rf12_initialize(myNodeID,freq,network); //node,433mhz, group 212
  Serial.print("Node: "); 
  Serial.print(myNodeID); 
  Serial.print(" Freq: "); 
  Serial.print(freq); 
  Serial.print(" Network: "); 
  Serial.println(network);

}

//********************************************************************
//LOOP
//********************************************************************
void loop() {

  if (measurement.power<1000) measurement.power=measurement.power+1; 
  else measurement.power=0;
  if (measurement.power<1000) measurement.temp=measurement.temp+10; 
  else measurement.temp=0;


  rfwrite() ;
  delay(2000); 
  
  Serial.print(measurement.power); 
  Serial.print(" "); 
  Serial.println(measurement.temp);
}


static void rfwrite(){

  

  for (byte i = 0; i < RETRY_LIMIT; ++i) {
    while (!rf12_canSend())
      rf12_recvDone();
    rf12_sendStart(RF12_HDR_ACK, &measurement, sizeof measurement, RADIO_SYNC_MODE);
    byte acked = waitForAck();

    if (acked) {
      Serial.print(" ack ");
      Serial.println((int) i);
      delay(2);  
      return  ;  
    }
    else Serial.print("No ack  ");
  }
}

// wait a few milliseconds for proper ACK to me, return true if indeed received
static byte waitForAck() {
  MilliTimer ackTimer;
  while (!ackTimer.poll(ACK_TIME)) {
    if (rf12_recvDone() && rf12_crc == 0 &&
      rf12_hdr == (RF12_HDR_DST | RF12_HDR_ACK | myNodeID))
      return 1;
  }
  return 0;
}




