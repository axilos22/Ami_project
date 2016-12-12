#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef enum {
	BROADCAST,
	ANSWER,
	CONFIRM,
	ACCEPT,
	REJECT} msg_type;

typedef enum {ALREADY,TIMEOUT} reason;

typedef enum {
	IDLE=0,
	BROADCASTING,
	W_BROADCASTING,
	ANSWERING,
	W_ANSWERING,
	CONFIRMING,
	W_CONFIRMING,
	ACCEPTING,
	W_ACCEPTING,
	REJECTING
} mote_state;

enum {
  AM_AMI = 6,
  TIMER_PERIOD_MILLI = 2500,
  MAX_MOTE=10
};

typedef struct printmessage{
	unsigned int moteID;
	char* msg;
	unsigned int msgLength;
} PrintMsg;

typedef struct amimessage {
	nx_uint16_t id_sender;
	nx_uint16_t id_receiver;
	msg_type type;
	nx_uint16_t channel;
	nx_uint16_t nextTime;
} AmiMsg;

typedef nx_struct BlinkToRadioMsg {
	nx_uint16_t nodeid;
	nx_uint16_t counter;
} BlinkToRadioMsg;
