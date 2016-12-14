#include "Timer.h"
#include "ami.h"

module AmIC @safe()
{  
  uses interface Timer<TMilli> as Timer;
  uses interface Leds;
  uses interface Boot;
  //messaging - sending
  uses interface Packet;
  uses interface AMPacket;
  uses interface AMSend;
  uses interface SplitControl as AMControl;
  //messaging - receiving
  uses interface Receive;
}
implementation
{
	//GLOBAL VARIABLES
	unsigned int cpt=0;
	//for radio communication
	bool busy=FALSE;
	message_t pkt;
	//FUNCTION SIGNATURES
	void setLed(const unsigned int value);
	void allLedOff(void);
	void allLedOn(void);
	void sendMessage(const unsigned int idReceiver,const msg_type type,const unsigned int channel,const unsigned int nextTime);
	
	event void Boot.booted(){
		//start up the radio comm
		call AMControl.start();
	}

	event void Timer.fired(){
		sendMessage(0,BROADCAST,0,0);
	}
	
	//------------------------------------ Radio comm - emission ------------------------------------
	event void AMControl.startDone(error_t err) {
		if (err == SUCCESS) {
			call Timer.startPeriodic(TIMER_PERIOD_MS);
		}else {
			call AMControl.start();
		}
	}

	event void AMControl.stopDone(error_t err) {
	}
	
	event void AMSend.sendDone(message_t* msg, error_t error) {
		if (&pkt == msg) {
			busy = FALSE;
		}
	}
	
	//------------------------------------ Radio comm - reception ------------------------------------
	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
		if (len == sizeof(AmiMsg)) {
			AmiMsg* inMsg = (AmiMsg*)payload;
			call Leds.set(inMsg->id_sender);
		}
		return msg;
	}
	
	//------------------------------------ My functions ------------------------------------
	void setLed(const unsigned int value){
		unsigned int scaledValue=value%8;
		allLedOff();
		if(scaledValue&1) {
			call Leds.led0On();
		}
		if(scaledValue&2) {
			call Leds.led1On();
		}
		if(scaledValue&4) {
			call Leds.led2On();
		}
  }
  
	void allLedOff(void){
		call Leds.led0Off();
		call Leds.led1Off();
		call Leds.led2Off();
	}
	void allLedOn(void){
		call Leds.led0On();
		call Leds.led1On();
		call Leds.led2On();
	}
	
	void sendMessage(const unsigned int idReceiver,const msg_type type,const unsigned int channel,const unsigned int nextTime){
		if (!busy) {
			AmiMsg* msg = (AmiMsg*)(call Packet.getPayload(&pkt, sizeof(AmiMsg)));
			msg->id_sender= TOS_NODE_ID;
			msg->id_receiver= idReceiver;
			msg->type=type;
			msg->channel=channel;
			msg->nextTime=nextTime;
			if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(AmiMsg)) == SUCCESS) {
				busy = TRUE;
				call Leds.led2Toggle();
			}
		}
	}
}
