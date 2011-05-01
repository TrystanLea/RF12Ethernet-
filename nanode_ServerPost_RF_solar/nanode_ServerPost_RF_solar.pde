#include <EtherCard.h>
#include <Ports.h>
#include <RF12.h> // needed to avoid a linker error :(

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
typedef struct {              //data structure to be received, must be same as on transmitter 
  int volts;
  int amps;
  int mw;
  int angle;
  int temp; 
} Payload;
Payload measurement; 
//########################################################################################################################

EtherCard eth;
MilliTimer requestTimer;
int test=1767;

static BufferFiller bufill;

static byte buf[300];   // a very small tcp/ip buffer is enough here

// called to fill in a request to send out to the client
static word my_datafill_cb (byte fd) {
    BufferFiller bfill = eth.tcpOffset(buf);
    bfill.emit_p(PSTR("GET /emoncms/api/api.php?json="));
    
    //--------------------------------------------------------------
    // JSON Data to send
    //--------------------------------------------------------------
    
    int power = 250;
    bfill.emit_p(PSTR("{nanode_power:$D}{nanode_temp:$D"),measurement.power), measurement.temp;
    
    //-------------------------------------------------------------- 
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

void setup () {
    Serial.begin(57600);
    Serial.println("\n[getStaticIP]");
    
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


static void homePage(BufferFiller& buf) {
   buf.emit_p(PSTR("$F\r\n"
   "<html><head></head><body style='background-color: #eee;'><div style='width: 800px; height:800px; background-color: #fff; border-width: 0px;"
   "-moz-border-radius: 7px; border-radius: 7px; padding:20px;'><img src='http://dev.openenergymonitor.org/nanode.png' style='width:200px;' />"
   "Power: $D  Temperature:$D"
   "<iframe id='testG' style='width:100%; height:500px;' frameborder='0' scrolling='no' marginheight='0' marginwidth='0' src='http://192.168.1.5/emoncms/vis/igraph.php?tableid=17&price=0.12'></iframe>"
   "</div></body></html>"),okHeader,measurement.power,measurement.temp);
}

void loop () {
    word len = eth.packetReceive(buf, sizeof buf);
    word pos = eth.packetLoop(buf, len);
 
    if (pos) {
      bufill = eth.tcpOffset(buf);
      char* data = (char *) buf + pos;
      Serial.println(data);

       //receive buf hasn't been clobbered by reply yet
       if (strncmp("GET / ", data, 6) == 0) homePage(bufill); 
        
       eth.httpServerReply(buf,bufill.position()); // send web page data
    }
       
       
    // Receive data from RFM12
    //if (rf12_recvDone() && rf12_crc == 0 && (rf12_hdr & RF12_HDR_CTL) == 0  )  
       if (rf12_recvDone() && rf12_crc == 0 && rf12_len==sizeof(Payload) ) {
        measurement=*(Payload*) rf12_data;      //decode packet binary data into known data structure (same as Tx) http://jeelabs.org/2010/12/08/binary-packet-decoding-%E2%80%93-part-2/
        Serial.print("Data: "); Serial.println(measurement.volts);        
        }
        
    
    
    
    
    if (eth.clientWaitingGw())
        return;
    
    if (requestTimer.poll(5000)) {
        Serial.print(">>> REQ# ");
        byte id = eth.clientTcpReq(my_result_cb, my_datafill_cb, hisport);
        Serial.println((int) id);
    }
}
