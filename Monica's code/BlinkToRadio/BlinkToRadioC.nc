 #include <Timer.h>
 #include "BlinkToRadio.h"
 
 module BlinkToRadioC {
   uses interface Boot;
   uses interface Leds;
   uses interface Timer<TMilli> as TimeOut;
   uses interface Timer<TMilli> as TimerWait;
   uses interface Timer<TMilli> as TimerToggle;
   uses interface Timer<TMilli> as TimerCheck;

  uses interface Packet as PacketAdd;
  uses interface AMPacket as AMPacketAdd;
  uses interface AMSend as AMSendAdd;
  uses interface SplitControl as AMControl;
  uses interface Receive as ReceiveAdd;

  uses interface Packet as PacketInfo;
  uses interface AMPacket as AMPacketInfo;
  uses interface AMSend as AMSendInfo;
  uses interface Receive as ReceiveInfo;
 }
 implementation {

  bool busy = FALSE;
  message_t pkt;

   uint16_t counter = 0;
   uint16_t currentIndex = 0;
   bool moteAnswered = FALSE;


   /* Mote list state*/
   uint16_t moteList[10];
   uint16_t channelList[10];
   uint16_t timeList[10];
   /* Current local state*/
   uint16_t step = 0;
   uint16_t comm_blink = 0;

  event void Boot.booted() {
    call AMControl.start();

  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {      
      call TimerWait.startOneShot(TOS_NODE_ID*1000);
      call TimerToggle.startPeriodic(TIMER_PERIOD_MILLI);
    }
    else {
      call AMControl.start();
    }
  }

event void TimerToggle.fired() {
	//CHANGE STATE TO LISTEN FOR INFORMATION
	if(step<5){
		step=6;
		//SEND INFO MESSAGE
		if (!busy) {
			InformationMsg* sendpkt = (InformationMsg*)(call PacketInfo.getPayload(&pkt, sizeof (InformationMsg)));
			sendpkt->my_nodeid = TOS_NODE_ID; 
			sendpkt->target_nodeid = moteList[0];
			sendpkt->message_type = 6;
			sendpkt->info = 0;
	    		if (call AMSendInfo.send(AM_BROADCAST_ADDR, &pkt, sizeof(InformationMsg)) == SUCCESS) {
				busy = TRUE;
	    		}
		}
	}else if(step==6){
		int i; 
		step=8;
		
		//loop to check how many nodes are in the list
		counter = 0;
    		for(i=0; i<10; i++){
    			if(moteList[i] != 0){        			
				counter = counter+1;
				if(counter==1){
					currentIndex=i;
				}
    			}
    		}
		
		//SEND CHECKING MESSAGE
		if (!busy) {		    
		    checkMoteMsg* sendpkt = (checkMoteMsg*)(call PacketInfo.getPayload(&pkt, sizeof (checkMoteMsg)));
		    sendpkt->my_nodeid = TOS_NODE_ID;
		    sendpkt->check_nodeid = moteList[currentIndex];    
		    sendpkt->message_type = 8;
		    if (call AMSendInfo.send(AM_BROADCAST_ADDR, &pkt, sizeof(checkMoteMsg)) == SUCCESS) {
			      busy = TRUE;		    
			      call TimerCheck.startOneShot(1000); 
			      call Leds.set(moteList[currentIndex]);
		    }
		}
	}else{
		step=0;
		call TimerWait.startOneShot(TOS_NODE_ID*1000);
	}
   }

  event void TimerCheck.fired() {
	int i;	
	if(!moteAnswered){
		moteList[currentIndex] = 0;
		channelList[currentIndex] = 0;
		timeList[currentIndex] = 0;	
	}else{
		moteAnswered=FALSE;
	}		
 	for(i=currentIndex+1; i<10; i++){
 		if(moteList[i] != 0){        			
			currentIndex = i;
 			i=11;
		}
	}
	call Leds.set(0); 
	if (!busy && counter>0) {		    
	    checkMoteMsg* sendpkt = (checkMoteMsg*)(call PacketInfo.getPayload(&pkt, sizeof (checkMoteMsg)));
	    sendpkt->my_nodeid = TOS_NODE_ID;
	    sendpkt->check_nodeid = moteList[currentIndex];    
	    sendpkt->message_type = 8;
	    if (call AMSendInfo.send(AM_BROADCAST_ADDR, &pkt, sizeof(checkMoteMsg)) == SUCCESS) {
		      busy = TRUE;
		      counter=counter-1;		    
		      call TimerCheck.startOneShot(1000);
		      call Leds.set(moteList[currentIndex]); 
	    }
	}
  }

  event void TimerWait.fired() {
	//SENDING FIRST BROADCAST MESSAGE	
	if(step==0){		
		call TimeOut.startOneShot(1000);		
		if (!busy) {		    
		    broadcastMsg* sendpkt = (broadcastMsg*)(call PacketAdd.getPayload(&pkt, sizeof (broadcastMsg)));
		    sendpkt->nodeid = TOS_NODE_ID;    
		    if (call AMSendAdd.send(AM_BROADCAST_ADDR, &pkt, sizeof(broadcastMsg)) == SUCCESS) {
			      busy = TRUE;
		    	      step=1; //wait 1s for broadcast answer			      			      
		    }
		}
	}
   }


  event void AMControl.stopDone(error_t err) {
  }
 
 event void AMSendAdd.sendDone(message_t* msg, error_t error) {
    if (&pkt == msg) {
      busy = FALSE;
    }
  }

 event void AMSendInfo.sendDone(message_t* msg, error_t error) {
    if (&pkt == msg) {
      busy = FALSE;
    }
  }


   event void TimeOut.fired() {
	if(step<5){
		step=0;
        	call TimerWait.startOneShot(TOS_NODE_ID*1000);
		call Leds.set(0);
	}
   }

event message_t* ReceiveAdd.receive(message_t* msg, void* payload, uint8_t len) {
	
  	
	//RECEIVED BROADCAST MESSAGE AT APPROPIATE TIME
  	if (step==0 && len == sizeof(broadcastMsg)) {
		bool alreadyInList=FALSE;
		broadcastMsg* btrpkt = (broadcastMsg*)payload;
    		
		//loop to check if nodeid is already in the list
		int i;
    		for(i=0; i<10; i++){
    			if(btrpkt->nodeid ==moteList[i]){        			
				alreadyInList = TRUE;
				call Leds.set(btrpkt->nodeid);
    			}
    		}
		
		//SEND ANSWER TO BROADCAST		
		if (!busy && !alreadyInList) {
			answerToBroadcastMsg* sendpkt = (answerToBroadcastMsg*)(call PacketAdd.getPayload(&pkt, sizeof (answerToBroadcastMsg)));
		    	sendpkt->my_nodeid = TOS_NODE_ID; 
			sendpkt->incoming_nodeid = btrpkt->nodeid;
			sendpkt->message_type = 1;
		    	if (call AMSendAdd.send(AM_BROADCAST_ADDR, &pkt, sizeof(answerToBroadcastMsg)) == SUCCESS) {
				busy = TRUE;
		    	}
			call Leds.set(2);
			step=2; //wait for channel proposal
		}
  	}

	//RECEIVED ANSWER TO BRODCAST
	if (step==1 && len == sizeof(answerToBroadcastMsg)) {
		answerToBroadcastMsg* received_pkt = (answerToBroadcastMsg*)payload;
    		
		//CONFIRM THE TYPE OF MESSAGE AND THAT THEY ARE TALKING TO US
		if(received_pkt->message_type == 1 && received_pkt->incoming_nodeid == TOS_NODE_ID){
			call Leds.set(3);
			//SEND CHANNEL PROPOSAL MESSAGE
			if (!busy) {
				channelProposalMsg* sendpkt = (channelProposalMsg*)(call PacketAdd.getPayload(&pkt, sizeof (channelProposalMsg)));
		    		sendpkt->my_nodeid = TOS_NODE_ID; 
				sendpkt->incoming_nodeid = received_pkt->my_nodeid;
				sendpkt->message_type = 2;
  				sendpkt->channel = AM_INFORMATION;
				sendpkt->time_toNextBroadcast = TOS_NODE_ID*1000;
		    		if (call AMSendAdd.send(AM_BROADCAST_ADDR, &pkt, sizeof(channelProposalMsg)) == SUCCESS) {
					busy = TRUE;
					step = 3;
		    		}
			}
		}					
  	}

	//RECEIVED CHANNEL PROPOSAL
	if (step==2 && len == sizeof(channelProposalMsg)) {
		channelProposalMsg* received_prop_pkt = (channelProposalMsg*)payload;
    		
		//CONFIRM THE TYPE OF MESSAGE AND THAT THEY ARE TALKING TO US
		if(received_prop_pkt->message_type == 2 && received_prop_pkt->incoming_nodeid == TOS_NODE_ID){
			call Leds.set(4);
			//SEND CHANNEL CONFIRMATION MESSAGE
			if (!busy) {
				channelConfirmationMsg* confpkt = (channelConfirmationMsg*)(call PacketAdd.getPayload(&pkt, sizeof (channelConfirmationMsg)));
		    		confpkt->my_nodeid = TOS_NODE_ID; 
				confpkt->incoming_nodeid = received_prop_pkt->my_nodeid;
				confpkt->message_type = 3;
		    		if (call AMSendAdd.send(AM_BROADCAST_ADDR, &pkt, sizeof(channelConfirmationMsg)) == SUCCESS) {
					int i;	
					bool added = FALSE;				
					busy = TRUE;
					step = 0;
					//PROCESS TO ADD NEW NODE TO LIST					
					for(i=0; i<10; i++){
						if(moteList[i]==received_prop_pkt->my_nodeid){
							added=TRUE;
						}						
						if(moteList[i]==0 && !added){
      							call Leds.set(5);
							moteList[i] = received_prop_pkt->my_nodeid;
							channelList[i] = AM_INFORMATION;
							timeList[i] = received_prop_pkt->time_toNextBroadcast;
							added=TRUE;
    						}
    					}
		    		}
			}

		} 		
	
  	}


	//RECEIVED CHANNEL CONFIRMATION
	if (step==3 && len == sizeof(channelConfirmationMsg)) {
		channelConfirmationMsg* received_conf_pkt = (channelConfirmationMsg*)payload;
    		
		//CONFIRM THE TYPE OF MESSAGE AND THAT THEY ARE TALKING TO US
		if(received_conf_pkt->message_type == 3 && received_conf_pkt->incoming_nodeid == TOS_NODE_ID){
			//PROCESS TO ADD NEW NODE TO LIST
			int i;
			bool added = FALSE;
			for(i=0; i<10; i++){
				if(moteList[i]==received_conf_pkt->my_nodeid){
					added=TRUE;
				}
				if(moteList[i]==0 && !added){
      					call Leds.set(5);
					moteList[i] = received_conf_pkt->my_nodeid;
					channelList[i] = AM_INFORMATION;
					timeList[i] = moteList[i]*1000;
					added=TRUE;
    				}
    			}
			step=0;
		} 		
	
  	}
  	return msg;
}


event message_t* ReceiveInfo.receive(message_t* msg, void* payload, uint8_t len) {
	
  	
	//RECEIVED INFORMATION MESSAGE 
  	if (sizeof(InformationMsg)) {
		InformationMsg* received_pkt = (InformationMsg*)payload;
    		
		//loop to check if nodeid is already in the list
		int i;
		bool inList;
    		for(i=0; i<10; i++){
    			if(received_pkt->my_nodeid ==moteList[i]){        			
				inList = TRUE;
    			}
    		}

		if(step==6 && received_pkt->message_type == 6 && received_pkt->target_nodeid == TOS_NODE_ID && inList){
			
			//SEND RESPONSE
			if (!busy) {
				InformationMsg* sendpkt = (InformationMsg*)(call PacketInfo.getPayload(&pkt, sizeof (InformationMsg)));								
				if(comm_blink == 0){
					call Leds.set(comm_blink);		
					comm_blink= 7;						
				}else{
					call Leds.set(received_pkt->my_nodeid);		
					comm_blink=0;
				}				
		    		sendpkt->my_nodeid = TOS_NODE_ID; 
				sendpkt->target_nodeid = received_pkt->my_nodeid;
				sendpkt->message_type = 6;
				sendpkt->info = 0;
		    		if (call AMSendInfo.send(AM_BROADCAST_ADDR, &pkt, sizeof(InformationMsg)) == SUCCESS) {
					busy = TRUE;
		    		}
			}
		}
	}

	if (len==sizeof(checkMoteMsg)) {
		checkMoteMsg* received_pkt = (checkMoteMsg*)payload;		
		//SEND ANSWER TO CHECK BROADCAST		
		if (!busy && received_pkt->message_type == 8 && received_pkt->check_nodeid == TOS_NODE_ID) {
			checkMoteMsg* sendpkt = (checkMoteMsg*)(call PacketInfo.getPayload(&pkt, sizeof (checkMoteMsg)));
		    	sendpkt->my_nodeid = TOS_NODE_ID; 
			sendpkt->check_nodeid = received_pkt->my_nodeid;
			sendpkt->message_type = 9;
		    	if (call AMSendInfo.send(AM_BROADCAST_ADDR, &pkt, sizeof(checkMoteMsg)) == SUCCESS) {
				busy = TRUE;
		    	}			
		}
		
		//CONFIRM THE TYPE OF MESSAGE AND THAT THEY ARE TALKING TO US
		if(received_pkt->message_type == 9 && received_pkt->check_nodeid == TOS_NODE_ID){
			moteAnswered=TRUE;
		}

	}
  	return msg;
}

 }
