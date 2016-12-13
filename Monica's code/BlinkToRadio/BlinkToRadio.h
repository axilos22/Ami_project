 #ifndef BLINKTORADIO_H
 #define BLINKTORADIO_H
 
 enum {
   AM_BROADCAST = 6,
   AM_INFORMATION = 8,
   TIMER_PERIOD_MILLI = 15250
 };

 typedef nx_struct broadcastMsg {
  nx_uint16_t nodeid;
} broadcastMsg;

 typedef nx_struct answerToBroadcastMsg {
  nx_uint16_t my_nodeid;
  nx_uint16_t incoming_nodeid;
  nx_uint16_t message_type; // == 1
} answerToBroadcastMsg; 

typedef nx_struct channelProposalMsg {
  nx_uint16_t my_nodeid;
  nx_uint16_t incoming_nodeid;
  nx_uint16_t message_type;  // == 2
  nx_uint16_t channel;
  nx_uint16_t time_toNextBroadcast;
} channelProposalMsg; 

typedef nx_struct channelConfirmationMsg {
  nx_uint16_t my_nodeid;
  nx_uint16_t incoming_nodeid;
  nx_uint16_t message_type;  // == 3
} channelConfirmationMsg; 

typedef nx_struct channelDenialMsg {
  nx_uint16_t my_nodeid;
  nx_uint16_t incoming_nodeid;
  nx_uint16_t message_type;  // == 4
  nx_uint16_t channel;
  nx_uint16_t time_toNextBroadcast;
} channelDenialMsg;

 typedef nx_struct InformationMsg {
  nx_uint16_t my_nodeid;
  nx_uint16_t target_nodeid;
  nx_uint16_t message_type;  // == 6
  nx_uint16_t info;
} InformationMsg;

 typedef nx_struct checkMoteMsg {
  nx_uint16_t my_nodeid;
  nx_uint16_t check_nodeid;
  nx_uint16_t message_type; // == 8 or 9
} checkMoteMsg; 


 #endif
