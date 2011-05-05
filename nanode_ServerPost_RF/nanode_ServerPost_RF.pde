//                              _      
//                             | |     
//  _ __   __ _ _ __   ___   __| | ___ 
// | '_ \ / _` | '_ \ / _ \ / _` |/ _ \
// | | | | (_| | | | | (_) | (_| |  __/
// |_| |_|\__,_|_| |_|\___/ \__,_|\___|
                                    
//EMONBASE V1
//GNU GPL V3
//openenergymonitor.org
//************************************

#include <EtherCard.h>
#include <Ports.h>
#include <RF12.h>

// ethernet interface mac address
static byte mymac[6] = { 0x54,0x55,0x58,0x10,0x00,0x26 };
// ethernet interface ip address
static byte myip[4] = { 192,168,1,100 };
// gateway ip address
static byte gwip[4] = { 192,168,1,1 };
// remote website ip address and port
static byte hisip[4] = { 192,168,1,5 };
static word hisport = 80;

// fixed RF12 settings
#define MYNODE 31            //node ID of nanode
#define freq RF12_433MHZ     //frequency
#define group 212            //network group 

//########################################################################################################################
//Data Structure to be received 
//########################################################################################################################
typedef struct {
  	  int ct1;		// current transformer 1
	  int ct2;		// current transformer 2
	  int nPulse;		// number of pulses recieved since last update
	  int temp1;		// One-wire temperature 1
	  int temp2;		// One-wire temperature 2
	  int temp3;		// One-wire temperature 3
	  int voltage;		// emontx voltage

	} Payload;
	Payload emontx;
//########################################################################################################################

EtherCard eth;
MilliTimer requestTimer;

static BufferFiller bufill;

static byte buf[300];   // a very small tcp/ip buffer is enough here

// called to fill in a request to send out to the client
static word my_datafill_cb (byte fd) {
    BufferFiller bfill = eth.tcpOffset(buf);
    //--------------------------------------------------------------
    // API URL
    //--------------------------------------------------------------
    bfill.emit_p(PSTR("GET /emoncms/api/api.php?json="));
    //--------------------------------------------------------------
    // JSON Data to send
    //--------------------------------------------------------------
    bfill.emit_p(PSTR("{emontx_ctA:$D,emontx_ctB:$D,nPulse:$D,temp1:$D}"),emontx.ct1, emontx.ct2, emontx.nPulse, emontx.temp1);
    bfill.emit_p(PSTR(" HTTP/1.1\r\n" "Host: localhost\r\n" "\r\n"));
    
    return bfill.position();
}

// called when the client request is complete
static byte my_result_cb (byte fd, byte status, word off, word len) {
    Serial.print("<<< reply ");
    Serial.println((int) status);
    Serial.print((const char*) buf + off);
    return 0;
}

//--------------------------------------------------------------------
// SETUP
//--------------------------------------------------------------------
void setup () {
    Serial.begin(57600);
    Serial.println("Nanode: emontx relay");
    
    eth.spiInit();
    eth.initialize(mymac);
    eth.initIp(mymac, myip, 80);
    eth.clientSetGwIp(gwip);    // outgoing requests need a gateway
    eth.clientSetServerIp(hisip);
    
    rf12_initialize(MYNODE, freq,group);
  
    requestTimer.set(1); // send first request as soon as possible
}
    
char okHeader[] PROGMEM = 
    "HTTP/1.0 200 OK\r\n"
    "Content-Type: text/html\r\n"
    "Pragma: no-cache\r\n"
    ;

//--------------------------------------------------------------------
// Generate the local webpage
//--------------------------------------------------------------------
static void homePage(BufferFiller& buf) {
   buf.emit_p(PSTR("$F\r\nRelaying JSON: {emontx_ctA:$D,emontx_ctB:$D,nPulse:$D,temp1:$D}"),okHeader,emontx.ct1, emontx.ct2, emontx.nPulse, emontx.temp1);
}

//--------------------------------------------------------------------
// MAIN LOOP
//--------------------------------------------------------------------
void loop () {
    word len = eth.packetReceive(buf, sizeof buf);
    word pos = eth.packetLoop(buf, len);

    //--------------------------------------------------------------------
    // 3) Serve a local web page
    //--------------------------------------------------------------------
    if (pos) {
       bufill = eth.tcpOffset(buf);
       char* data = (char *) buf + pos;
       Serial.println(data);

       //receive buf hasn't been clobbered by reply yet
       if (strncmp("GET / ", data, 6) == 0) homePage(bufill); 
        
       eth.httpServerReply(buf,bufill.position()); // send web page data
    }
       
    //--------------------------------------------------------------------
    // 1) Receive data from RFM12
    //--------------------------------------------------------------------
    if (rf12_recvDone() && rf12_crc == 0 && (rf12_hdr & RF12_HDR_CTL) == 0 && rf12_len==sizeof(Payload) ) {
        emontx=*(Payload*) rf12_data;   
    }
        
    if (eth.clientWaitingGw()) return;
    
    //--------------------------------------------------------------------
    // 2) Relay data on to emoncms
    //--------------------------------------------------------------------
    if (requestTimer.poll(5000)) {
        Serial.print(">>> REQ# ");
        byte id = eth.clientTcpReq(my_result_cb, my_datafill_cb, hisport);
        Serial.println((int) id);
    }
}
