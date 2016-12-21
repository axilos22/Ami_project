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
	components new TimerMilliC() as resetTimer;
	//wiring
	AmIC.sendTimer -> Timer;
	AmIC.resetTimer -> resetTimer;
	
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
	//Printing
	components SerialActiveMessageC, PlatformSerialC;
	AmIC.Serial -> PlatformSerialC;
	AmIC.SerialControl -> SerialActiveMessageC;
}
