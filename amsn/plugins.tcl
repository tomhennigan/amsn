#Plugins system, preliminary verion

#List of available event types, and their parameters:
#
# chat_msg_received { userlogin userName msgText }
#
# chat_msg_sent

namespace eval ::plugins {

   namespace export PostEvent

   if { $initialize_amsn == 1 } {
       variable pluginslist [list]
       variable registeredfiles [list]
   }

   proc PostEvent { event args } {
       variable pluginslist 
       variable pluginsevents 

       foreach plugin $pluginslist {
	   status_log "$plugin\n"
	   set plugin [lindex $plugin 0]
	   if { [info exists pluginsevents(${plugin}_${event}) ] } {
	       catch { ::${plugin}::$pluginsevents(${plugin}_${event}) args } res
	       status_log "Return $res from event $event of plugin $plugin\n"
	   }
       }

   }
 
   proc RegisterPlugin { plugin  description } {
       variable pluginslist

       if { [lsearch $pluginslist "$plugin *"] } {
	   status_log "Trying to register a plugin twice..\n"
	   return 
       }
       
       lappend plugin "$description"
       lappend pluginslist $plugin


       status_log "New plugin :\nName : [lindex $plugin 0]\nDescription : $description\n"
   }
   
   proc RegisterEvent { plugin event cmd } {
       variable pluginslist 
       variable pluginsevents

       if { [lsearch $pluginslist "$plugin *"] != -1 } {
	   status_log "Binding $event to ::$plugin::$cmd\n"
	   set pluginsevents(${plugin}_${event}) $cmd
       } else {
	   status_log "Registering an event for an unknown plugin...\n"
       }
   }

   proc findplugins { } {
       global HOME

       set search_path [list] 
       lappend search_path plugins
       lappend search_path [file join $HOME plugins]
       
       set ret [list]
       foreach dir $search_path {
	   if { [catch {set files [glob -directory $dir */plugin.tcl]} ] != 0 } {
	       set files [list]
	   }
	   status_log "Found plugin files in $files\n"
	   foreach file $files {
	       set plugin $file
	       set dirname [string map [list "$dir/" ""] [file dirname $file] ]
	       set desc ""
	       if { [file readable [file join [file dirname $file] desc.txt] ] } {
		   set fd [open [file join [file join [file dirname $file] desc.txt] desc.txt]]
		   set desc [string trim [read $fd]]
		   status_log "plugin $dirname has description : $desc\n"
		   close $fd
	       }
	       lappend plugin $dirname
	       lappend plugin $desc
	       lappend ret $plugin

	   }
       }

       return $ret
   }

   proc PluginGui { } {
       variable pluginslist
       variable plugins

       set w .plugin_selector 
       toplevel $w
       wm geometry $w 400x300
       
       label $w.choose -text "[trans selectplugins] : "
       pack $w.choose -side top
       

       set idx 0
                
       foreach plugin [findplugins] {

	   if { [lsearch  $pluginslist "$plugin *"] != -1 } { 
	       set plugins($idx) 1
	   } else {
	       set plugins($idx) 0
	   }
	   
	   status_log "Got new plugin : $plugin --- [lindex $plugin 0] ;-; [lindex $plugin 1] ;-; [lindex $plugin 2]\n"

	   checkbutton $w.$idx -text "[lindex $plugin 1]" -onvalue 1 -offvalue 0 -variable plugins($idx)
	   label $w.l$idx -text "[lindex $plugin 2]"

	   set plugins(${idx}_file) [lindex $plugin 0]

	   pack $w.$idx $w.l$idx -side left
	   incr idx
       }

       if { $idx == 0 } {
	   label $w.status -text "[trans noneavailable]"
	   pack $w.status
       }
       
       status_log "[array get plugins]\n"
       button $w.ok -text "[trans ok]" -command "::plugins::pluginsguiok $w $idx"
       button $w.cancel -text "[trans cancel]" -command "destroy $w"
       
       pack $w.ok $w.cancel -side right


       bind $w <Destroy> "grab release $w"
       
       grab set $w
       
   }

   proc pluginsguiok { w idxmax } {
       variable plugins
       variable pluginslist
       global config

       status_log "Got ok from plugin selector --- [array get plugins]\n"

       for { set idx 0 } { $idx < $idxmax } { incr idx } {

	   set state $plugins($idx)
	   set file $plugins(${idx}_file)
	   set plugin $plugins(${idx}_name)

	   if { $state == 1 && [lsearch $pluginslist "$file *"] == -1 } {
	       catch { source $file }
	       lappend pluginslist $file
	       lappend config(activeplugins) $plugin
	   } elseif { $state == 0 && [lsearch $pluginslist "$file *"] != -1 } {
	       
	   }
       }
	}
}
