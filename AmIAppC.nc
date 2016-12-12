configuration AmIAppC
{
	provides interface Init;
	provides interface ParameterInit<uint16_t> as SeedInit;
	provides interface Random;
}
implementation
{
  components MainC, LedsC, AmIC;
  components new TimerMilliC() as Timer;
  components new TimerMilliC() as SleepTimer;
  components new TimerMilliC() as ListeningTimer;  
  components new TimerMilliC() as SendingTimer;

  //Serial port
  components SerialActiveMessageC;
  //components new SerialAMSenderC(AM_BLINKTORADIOMSG);
  components PlatformSerialC;


  AmIC -> MainC.Boot;

  AmIC.SleepTimer -> SleepTimer;
  AmIC.ListeningTimer -> ListeningTimer;
  AmIC.SendingTimer -> SendingTimer;
  
  AmIC.SerialControl->SerialActiveMessageC;
  AmIC.SerialImp->PlatformSerialC;
  
  AmIC.Leds -> LedsC;
  
  components RandomMlcgC;
  
  Init = RandomMlcgC;
  SeedInit = RandomMlcgC;
  Random = RandomMlcgC;
  
  //COMMUNICATION
  components ActiveMessageC;
  components new AMSenderC(AM_AMI);
  
  AmIC.Packet -> AMSenderC;
  AmIC.AMPacket -> AMSenderC;
  AmIC.AMSend -> AMSenderC;
  AmIC.AMControl -> ActiveMessageC;
  
  components new AMReceiverC(AM_AMI);
  AmIC.Receive -> AMReceiverC;
}
