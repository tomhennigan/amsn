#Plugins system, preliminary verion

#List of available event types, and their parameters:
#
# chat_msg_received
#
# chat_msg_sent

namespace eval ::plugins {

   namespace export postEvent
   
   proc postEvent { evID evParam { evProtocol "MSN" } } {
      #Here, we should check registered plugins listening for
      #the incoming event. For the moment, let's just switch
      
      switch evID {
         default {
	    status_log "::plugins::postEvent: Unknown event type: $evID\n" red
	 }
      }
   }
   
}