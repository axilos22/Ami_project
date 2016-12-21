#include <stdio.h>
#include "Timer.h"
#include "ami.h"

module AmIC @safe()
{  
  uses interface Timer<TMilli> as sendTimer;
  uses interface Timer<TMilli> as resetTimer;
  uses interface Leds;
  uses interface Boot;
  //messaging - sending
  uses interface Packet;
  uses interface AMPacket;
  uses interface AMSend;
  uses interface SplitControl as AMControl;
  //messaging - receiving
  uses interface Receive;
  //serial port communication
  uses interface UartStream as Serial;
  uses interface SplitControl as SerialControl;
}
implementation
{
	//GLOBAL VARIABLES
	unsigned int cpt=0;
	//for radio communication
	bool busy=FALSE;
	message_t pkt;
	AmiMsg* outMsg;
	//mote state
	mote_state state=IDLE;
	mote_state nextState=IDLE;
	//mote tables
	bool pairings[MOTE_NB];
	unsigned int channels[MOTE_NB];
	unsigned int nextTimes[MOTE_NB];
	//mote default values
	const unsigned int defaultChannel=118;
	const unsigned int defaultNextTime=712;
	//FUNCTION SIGNATURES
	void serialSendString(char* string);
	void setLed(const unsigned int value);
	void allLedOff(void);
	void allLedOn(void);
	void setMessage(const unsigned int idReceiver,const msg_type type,const unsigned int channel,const unsigned int nextTime);
	void sendMessage();
	void processMessage(AmiMsg* msg);
	void updateState();
	void updateTables(const unsigned int moteId, const unsigned int channel,const unsigned int nextTime);
	
	event void Boot.booted(){
		int rank;
		//init arrays
		for(rank=0;rank<MOTE_NB;rank+=1) {
			pairings[rank]=FALSE;
			channels[rank]=0;
			nextTimes[rank]=0;
		}
		//mote is paired with itself
		pairings[TOS_NODE_ID]=TRUE;
		//start up the radio comm
		call AMControl.start();
		//set the comm message
		outMsg = (AmiMsg*)(call Packet.getPayload(&pkt, sizeof(AmiMsg)));
		
		setMessage(0,BROADCAST,0,0);
		call resetTimer.startPeriodic(RESET_TIMER_MS);
		call SerialControl.start();
	}
	
	event void resetTimer.fired(){
		//reset the mote to initial state (robustness)
		//the mote will perform a full pairing cycle only once every (this period)
		state=IDLE;
		nextState=BROADCASTING;
	}
	
	//------------------------------------ Radio comm - emission ------------------------------------
	event void sendTimer.fired() {
		//setMessage(0,BROADCAST,0,0);
		sendMessage();
		updateState();
	}

	event void AMControl.startDone(error_t err) {
		if (err == SUCCESS) {
			call sendTimer.startPeriodic(TIMER_PERIOD_MS);
		} else {
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
			processMessage(inMsg);
		}
		return msg;
	}

	//------------------------------------ Serial port control ------------------------------------ 
	event void SerialControl.startDone(error_t error) {
	}

	event void SerialControl.stopDone(error_t error) {
	}

	//------------------------------------ Serial handling events ------------------------------------
	async event void Serial.sendDone( uint8_t* buf, uint16_t len, error_t error )
	{
	}

	async event void Serial.receivedByte( uint8_t byte )
	{
	}

	async event void Serial.receiveDone( uint8_t* buf, uint16_t len, error_t error )
	{
	}
	
	//------------------------------------ My functions ------------------------------------
	void serialSendString(char* string)
	{
		unsigned char* outStr = (unsigned char*)string;
		call Serial.send(outStr, strlen(outStr));
	}

	void setLed(const unsigned int value)
	{
		unsigned int scaledValue=value%8;
		//allLedOff();
		call Leds.led0Off();
		call Leds.led1Off();
		if(scaledValue&1) {
			call Leds.led0On();
		}
		else if(scaledValue&2) {
			call Leds.led1On();
		}
		else if(scaledValue&4) {
			call Leds.led2On();
		}
	}
  
	void allLedOff(void) {
		call Leds.led0Off();
		call Leds.led1Off();
		call Leds.led2Off();
	}
	void allLedOn(void) {
		call Leds.led0On();
		call Leds.led1On();
		call Leds.led2On();
	}
	
	void sendMessage() {
		if (!busy) {
			if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(AmiMsg)) == SUCCESS) {
				busy = TRUE;
				call Leds.led2Toggle();
			}
		}
	}

	void processMessage(AmiMsg* msg){
		char serialMessage[100];
		unsigned int sender =msg->id_sender;
		unsigned int receiver=msg->id_receiver;
		msg_type type = msg->type;
		switch(state){
			case IDLE:
				if(type==BROADCAST){
					setMessage(sender,ANSWER,0,0);
					nextState=WAIT_CONF;
				}
			break;
			case BROADCASTING:
				if(type==BROADCAST){
					setMessage(sender,ANSWER,0,0);
					nextState=WAIT_CONF;
				}
				if(type==ANSWER && receiver==TOS_NODE_ID){
					setMessage(sender,CONFIRM,22,200);
					nextState=WAIT_RESPONSE;
				}
			break;
			case WAIT_CONF:
				if(type==CONFIRM && receiver==TOS_NODE_ID){
					if(pairings[sender]==FALSE){//I am not paired. it is ok
						setMessage(sender,ACCEPT,defaultChannel,defaultNextTime);
						updateTables(sender,msg->channel,msg->nextTime);
						nextState=IDLE;
					}else {//i am paired, i cant add you
						setMessage(sender,REJECT,0,0);
						nextState=IDLE;
						sprintf(serialMessage, "[%d]Pairing already exists, rejecting\n",TOS_NODE_ID);
						serialSendString(serialMessage);
					}
					
				}
			break;
			case WAIT_RESPONSE:
				if(type==ACCEPT && receiver==TOS_NODE_ID){
					updateTables(sender,msg->channel,msg->nextTime);
					nextState=IDLE;
					sprintf(serialMessage, "[%d]Pairing accepted\n",TOS_NODE_ID);
					serialSendString(serialMessage);
				}
				if(type==REJECT && receiver==TOS_NODE_ID){
					nextState=IDLE;
					sprintf(serialMessage, "[%d]Pairing rejected\n",TOS_NODE_ID);
					serialSendString(serialMessage);
				}
			break;
		}
	}
	
	void setMessage(const unsigned int idReceiver,const msg_type type,const unsigned int channel,const unsigned int nextTime){
		outMsg->id_sender= TOS_NODE_ID;
		outMsg->id_receiver= idReceiver;
		outMsg->type=type;
		outMsg->channel=channel;
		outMsg->nextTime=nextTime;
	}
	
	void updateState(){
		char serialMessage[100];
		sprintf(serialMessage, "[%d]State %d --> %d\n",TOS_NODE_ID,state,nextState);
		if(state!=nextState)
			serialSendString(serialMessage);
		state=nextState;
		//call Leds.set(state);
		setLed(state);
	}
	
	void updateTables(const unsigned int moteId, const unsigned int channel,const unsigned int nextTime){
		char serialMessage[100];
		sprintf(serialMessage, "[%d]Updating pairing table\n",TOS_NODE_ID);
		pairings[moteId]=TRUE;
		channels[moteId]=channel;
		nextTimes[moteId]=nextTime;
		//TODO add significant LED behavior to prove this point has been reached
		//call sendTimer.stop();//stop sending data
	}
}
