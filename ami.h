#ifndef AMI_H
#define AMI_H

//PARAMETERS
enum {
	AM_AMI = 6,
	TIMER_PERIOD_MS = 250,
	RESET_TIMER_MS = 3000,
	MOTE_NB = 10
};
//Message types
typedef enum {
	BROADCAST,
	ANSWER,
	CONFIRM,
	ACCEPT,
	REJECT} msg_type;
//mote states
typedef enum {
	IDLE=0,
	BROADCASTING=1,
	WAIT_CONF=2,
	WAIT_RESPONSE=3
} mote_state;
//AMI message
typedef struct amimessage {
	nx_uint16_t id_sender;
	nx_uint16_t id_receiver;
	msg_type type;
	nx_uint16_t channel;
	nx_uint16_t nextTime;
} AmiMsg;
#endif
