# Ami_project
The AmI project's goal is to create a network of sensor using the tinyOS operating system running on and micaz motes.

#How to run ?
-Connect a mote to the system. And execute the makeInstall.sh script.
This will compile the code and upload it to the first mote.
note: by default, the ID of this mote is 1.

-Then when the compilation and flashing are completed sucessfully, unplug the mote and make it run on batteries.

-The mote should normally flash the LED2 (yellow) (indicator of sending data) and Oscillate between the 
IDLE state (LED1 and LED0 off) and BROADCASTING state (LED0 on, LED1 off).
 
-Connect the second mote and run the script "makeInstall2.sh". (mote ID is 2)

-The motes should now communicate and the change of state should be visible.

#Debugging
-A subroutine has been implemented allowing to print information on the USB1 port. The commands to run are stored into "output.sh".

-Running the script directly may have some unexpected behavior, so it is safer to execute these two commands in a terminal.

#Troubleshooting
-The mote only pair once.
It is normal that the pairing only happend once. A paired mote will automatically refuse any pairing with an already paired mote.

-"Programmer is not responding" a frequent error due to memory flashing. Multiple retries solve this issue.

