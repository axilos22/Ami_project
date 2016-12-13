 #include <Timer.h>
 #include "BlinkToRadio.h"
 
 configuration BlinkToRadioAppC {
 }
 implementation {
   components MainC;
   components LedsC;
   components BlinkToRadioC as App;
   components new TimerMilliC() as TimeOut;
   components new TimerMilliC() as TimerWait;
   components new TimerMilliC() as TimerToggle;
   components new TimerMilliC() as TimerCheck;

  components ActiveMessageC;
  components new AMSenderC(AM_BROADCAST) as SenderAdd;
  components new AMReceiverC(AM_BROADCAST) as ReceiverAdd;

  components new AMSenderC(AM_INFORMATION) as SenderInfo;
  components new AMReceiverC(AM_INFORMATION) as ReceiverInfo;

  App.PacketAdd -> SenderAdd;
  App.AMPacketAdd -> SenderAdd;
  App.AMSendAdd -> SenderAdd;
  App.ReceiveAdd -> ReceiverAdd;
 
  App.PacketInfo -> SenderInfo;
  App.AMPacketInfo -> SenderInfo;
  App.AMSendInfo -> SenderInfo;
   App.ReceiveInfo -> ReceiverInfo;

  App.AMControl -> ActiveMessageC;

   App.Boot -> MainC;
   App.Leds -> LedsC;
   App.TimeOut -> TimeOut;
   App.TimerWait -> TimerWait;
   App.TimerToggle -> TimerToggle;
   App.TimerCheck -> TimerCheck;
 }
