#include "Timer.h"
#include "ami.h"

static uint8_t counter = 0;
module AmIC @safe()
{
    uses interface Timer<TMilli> as SleepTimer;
    uses interface Timer<TMilli> as ListeningTimer;
    uses interface Timer<TMilli> as SendingTimer;
    uses interface Leds;
    uses interface Boot;
    uses interface Random;
    
    //COMMUNICATION
    uses interface Packet;
    uses interface AMPacket;
    uses interface AMSend;
    uses interface SplitControl as AMControl;
    uses interface SplitControl as SerialControl;
    uses interface Receive;
    uses interface UartStream as SerialImp;
}
implementation
{
	//COMMUNICATION
	bool busy = FALSE;
	message_t pkt;
	AmiMsg* myMsg;
	unsigned int channelCounter;
	unsigned int nextTime;
	//STATES management
	mote_state state=IDLE;
	mote_state previousState=IDLE;
	//PAIRING TABLE
	bool pairT[20]={FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE,FALSE};
	nx_uint16_t channelT[20]={0,0,0,0,0 ,0,0,0,0,0 ,0,0,0,0,0 ,0,0,0,0,0};
	nx_uint16_t nextTimeT[20]={0,0,0,0,0 ,0,0,0,0,0 ,0,0,0,0,0 ,0,0,0,0,0};
	bool isPaired=FALSE;
	//PERIODS
	int listeningPeriod = 250;
	//DEBUGGING
	//int debugSize=2000;
	//char *debugMsg;


	event void Boot.booted(){
		unsigned char str[1024];
	
		dbg("AmIc","Mote initialized");
		call Leds.led0On();
		call Leds.led1On();
		call Leds.led2On();//all leds on while init
		//Init radio
		call AMControl.start();
		call SerialControl.start();
		
		//call SendingTimer.startPeriodic( 2000 ); //sending every 2sec
		//call SleepTimer.startPeriodic(10000);//sleeping every 10s
		call ListeningTimer.startPeriodic(listeningPeriod);//updating LED every 500ms
		
		channelCounter=0;
		nextTime=1234;
		
		/*Defining default broadcast message*/
		myMsg = (AmiMsg*)(call Packet.getPayload(&pkt, sizeof (AmiMsg)));
		myMsg->id_sender = TOS_NODE_ID;
		myMsg->id_receiver = 0;
		myMsg->type = BROADCAST;
		myMsg->channel = 0;
		myMsg->nextTime = 0;
		
		//Broadcasting
		previousState=state;
		state=BROADCASTING;
		
		call Leds.led0Off();
		call Leds.led1Off();
		call Leds.led2Off();
		
		sprintf(str, "Mote initialized. ID=%d listenP=%d", TOS_NODE_ID, listeningPeriod);
		call SerialImp.send(str,strlen(str));
	}

	event void SendingTimer.fired() {
		unsigned char str[1024];
		//call Leds.led0Toggle();
		//dbg("AmIC","Should send data now");
		
		sprintf(str, "ID=%d : Sending a message type: %d", TOS_NODE_ID, myMsg->type);
		call SerialImp.send(str,strlen(str));
		
		if (!busy) {
			//BlinkToRadioMsg* btrpkt = (BlinkToRadioMsg*)(call Packet.getPayload(&pkt, sizeof (BlinkToRadioMsg)));
			if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(AmiMsg)) == SUCCESS) {
				busy = TRUE;
				dbg("AmIC","Message succesfuly sent");
			}
		}
		call Leds.led1On();//reached end of sending
	}

	event void SleepTimer.fired() {
		dbg("AmIC","Going to sleep now");
		//call Leds.led2Toggle();
		//sleep();
	}
	/*LED UPDATOR*/
	event void ListeningTimer.fired() {
		call SerialImp.send("Updating LED",strlen("Updating LED"));
		//unsigned char str[80];
		//sprintf(str, "testNB %d", 10);
		//call SerialImp.send(str,strlen(str));
		//call SerialImp.send("PRINTTTTTTT\n",strlen("PRINTTTTTTT\n"));
		dbg("AmIC","UPDATE LEDS");
		if(isPaired==FALSE) {
			call Leds.led1Off();
		} else {
			call Leds.led1On();
		}
		switch(state){
			case BROADCASTING:
				//0blink
				call Leds.led0Off();
				call Leds.led2Toggle();
				break;
			case ANSWERING:
				//01
				call Leds.led0Off();
				call Leds.led2On();
				break;
			case CONFIRMING:
				//10
				call Leds.led0On();
				call Leds.led2Off();
				break;
			case ACCEPTING:
				//11
				call Leds.led0On();
				call Leds.led2On();
				break;
			case REJECTING:
				break;
			default:
			break;
		}
	}
	

	event void AMControl.startDone(error_t err) {
		if (err == SUCCESS) {
			dbg("AmIC","Will periodically send data");
			call SendingTimer.startPeriodic(TIMER_PERIOD_MILLI);
		}
		else {
			call AMControl.start();
		}
	}

	event void AMControl.stopDone(error_t err) {
	}

	event void AMSend.sendDone(message_t* msg, error_t error) {
		if (&pkt == msg) {
			busy = FALSE;
			dbg("AmIC","Message sending --> OK");
		}
	}

	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
		call Leds.led1Toggle();
		if (len == sizeof(AmiMsg)) {
			AmiMsg* btrpkt = (AmiMsg*)payload;
			switch(btrpkt->type){
				case BROADCAST:
					dbg("AmIC","Checking if mote is in the list");
					if(pairT[btrpkt->id_sender]==FALSE) {
						dbg("Mote is not in the list");
						myMsg->id_sender = TOS_NODE_ID;
						myMsg->id_receiver = btrpkt->id_sender;
						myMsg->type = ANSWER;
						previousState=state;
						state=ANSWERING;
					} else {
						dbg("AmIC","Mote is in the list --> No action performed");
					}
					break;
				case ANSWER:
					if(btrpkt->id_receiver ==TOS_NODE_ID) {
						dbg("AmIC","i was broadcasting and i got an answer");
						/*Now i send confirmation*/
						myMsg->id_sender = TOS_NODE_ID;
						myMsg->id_receiver = btrpkt->id_sender;
						myMsg->type = CONFIRM;
						myMsg->channel =channelCounter;
						channelCounter=channelCounter+1;
						myMsg->nextTime=nextTime;
						dbg("AmIC","I am confirming the linking");
						previousState=state;
						state=CONFIRMING;
					} else {
						dbg("AmIC","this answer is not for me");
					}
				break;
				case CONFIRM:
					if(btrpkt->id_receiver ==TOS_NODE_ID) {
						if(previousState==ANSWERING) {
							dbg("AmIC","I answered and I got a confirmation");
							channelT[btrpkt->id_sender]=btrpkt->channel;
							nextTimeT[btrpkt->id_sender]=btrpkt->nextTime;
						}
					} else {
						dbg("AmIC","this confirmation is not for me");
					}
				break;
				case ACCEPT:
					if(btrpkt->id_receiver ==TOS_NODE_ID) {
						pairT[btrpkt->id_sender]=TRUE;
						isPaired=TRUE;
						dbg("AmIC","i add the sender to the pairing table");
					} else {
						dbg("AmIC","this acceptance is not for me");
					}
				break;
				case REJECT:
					if(btrpkt->id_receiver ==TOS_NODE_ID) {
						pairT[btrpkt->id_sender]=FALSE;
						dbg("AmIC","I got rejected");
					} else {
						dbg("AmIC","this rejection is not for me");
					}
				break;
				default:
				break;
			}
			//dbg("AmIc","Got a message");
			//call Leds.set(btrpkt->counter);
		}
		return msg;
	}
	
	async event void SerialImp.sendDone(uint8_t* buf, uint16_t len, error_t error) {
	}
	
	async event void SerialImp.receivedByte(uint8_t byte){
	}
	
	async event void SerialImp.receiveDone(uint8_t* buf, uint16_t len, error_t error) {
	
	}
	
	event void SerialControl.startDone(error_t error) {
	}
	
	event void SerialControl.stopDone(error_t error) {
	}

}

