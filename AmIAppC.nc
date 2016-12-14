configuration AmIAppC
{
}
implementation
{
	components MainC, AmIC, LedsC;
	//wiring
	AmIC -> MainC.Boot;
	AmIC.Leds -> LedsC;
	
	//timer
	components new TimerMilliC() as Timer;
	//wiring
	AmIC.Timer -> Timer;
	
	//radio comm - sending
	components ActiveMessageC;
	components new AMSenderC(AM_AMI);
	//wiring
	AmIC.Packet -> AMSenderC;
	AmIC.AMPacket -> AMSenderC;
	AmIC.AMSend -> AMSenderC;
	AmIC.AMControl -> ActiveMessageC;
	
	//radio comm - reception
	components new AMReceiverC(AM_AMI);
	//wiring
	AmIC.Receive -> AMReceiverC;
}
