#Plugins system, preliminary verion

#List of available event types, and their parameters:
#
# chat_msg_received { userlogin userName msgText }
#
# chat_msg_sent

namespace eval ::plugins {

   namespace export postEvent
   
   proc postEvent { evID evParam { evProtocol "MSN" } } {
      #Here, we should check registered plugins listening for
      #the incoming event. For the moment, let's just switch
      
      switch $evID {
         chat_msg_received {
	    global config
	    
	    #Ircha plugin
	    if {[info exists config(ircha)]} {
  	       if { $config(ircha) } {
	          status_log "Running text2speech: \n" 
	          catch {exec artsdsp lee "\"[trans says [lindex $evParam 1]]: [lindex $evParam 2]\"" &}
	       }
	    }
	 }
         default {
	   # status_log "::plugins::postEvent: Unknown event type: $evID\n" red
	 }
      }
   }
   
}
