#############################################################################
#  ::DbusViewer => aMSN's graphical dbus monitor and filter.				#
#  ======================================================================== #
# 	This plugin enables you to monitor dbus messages 						#
#	using the event log of aMSN.											#
#																			#
#   Author: Jonne Zutt <amsn-dbus@zutt.org>									#
#############################################################################

namespace eval ::DbusViewer {
  variable bus1_fileptr
  variable bus1_state 0
  variable bus2_fileptr
  variable bus2_state 0

  ###########################################################################
  # ::DbusViewer::Init (dir)                   								#
  # ----------------------------------------------------------------------- #
  # Registration & initialization of the plugin								#
  ###########################################################################
  proc Init { dir } {
    global bus1_fileptr
    global bus1_state
    global bus2_fileptr
    global bus2_state

    ::plugins::RegisterPlugin "DbusViewer"
    # Handle plugin configuration
    ::DbusViewer::config_array
    ::DbusViewer::configlist_values

    # Start bus 1
    if {$::DbusViewer::config(dbus_bt_1)} {
      if { [catch {open [concat "|" $::DbusViewer::config(dbus_cmd_1)] r} bus1_fileptr] } {
        log [concat "Cannot execute dbus 1 command: " $::DbusViewer::config(dbus_cmd_1)]
      } else {
        set bus1_state 1
        fconfigure $bus1_fileptr -blocking 0 -buffering none
        fileevent $bus1_fileptr readable [list ::DbusViewer::ProcessMessage 1]
        log "bus 1 started"
      }
    }
    # Start bus 2
    if {$::DbusViewer::config(dbus_bt_2)} {
      if { [catch {open [concat "|" $::DbusViewer::config(dbus_cmd_2)] r} bus2_fileptr] } {
        log [concat "Cannot execute dbus 2 command: " $::DbusViewer::config(dbus_cmd_2)]
      } else {
        set bus2_state 1
        fconfigure $bus2_fileptr -blocking 0 -buffering none
        fileevent $bus2_fileptr readable [list ::DbusViewer::ProcessMessage 2]
        log "bus 2 started"
      }
    }

  }

  ###########################################################################
  # ::DbusViewer::ProcessMessage               								#
  # ----------------------------------------------------------------------- #
  # Process incoming bus signal												#
  ###########################################################################
  proc ProcessMessage { bus } {
    global bus1_fileptr
    global bus1_state
    global bus2_fileptr
    global bus2_state

    if {$bus == 1} {
      set fileptr $bus1_fileptr
    } else {
      set fileptr $bus2_fileptr
    }

    while {[gets $fileptr line] >= 0} {

      # Check all enabled 'REs that should match'
      set match 0
      set pretty ""
      foreach {i bt re} \
              {1 dbus_bt_match_1 dbus_re_match_1 \
               2 dbus_bt_match_2 dbus_re_match_2 \
               3 dbus_bt_match_3 dbus_re_match_3 \
               4 dbus_bt_match_4 dbus_re_match_4 \
               5 dbus_bt_match_5 dbus_re_match_5} {
        if {$match == 0 && $::DbusViewer::config($bt)} {
          set lst [regexp -inline $::DbusViewer::config($re) $line]
          if {"$lst" != ""} {
            set skip_first 0
            foreach {match} $lst {
              if {$skip_first > 0} {
                set pretty "$pretty$match"
              }
              incr skip_first
              set match $i
            }
          }
        }
      }

      # Check all enabled 'REs that should fail'
      set fail 0
      foreach {i bt re} \
              {1 dbus_bt_fail_1 dbus_re_fail_1 \
               2 dbus_bt_fail_2 dbus_re_fail_2 \
               3 dbus_bt_fail_3 dbus_re_fail_3 \
               4 dbus_bt_fail_4 dbus_re_fail_4 \
               5 dbus_bt_fail_5 dbus_re_fail_5} {
        if {$fail == 0 && $::DbusViewer::config($bt) && \
            [regexp $::DbusViewer::config($re) $line]} {
          set fail $i
        }
      }

      if {$::DbusViewer::config(dbus_ignore_res) ||
          ($match > 0 && $fail == 0)} {
        if {$::DbusViewer::config(dbus_ignore_res)} {
          set prefix "\[$match $fail\] "
        } else {
          set prefix ""
        }
        if { "$pretty" != "" } {
          ::amsn::notifyAdd "$prefix$pretty" ""
        } else {
          ::amsn::notifyAdd "$prefix$line" ""
        }
        log "Signal: prefix=$prefix pretty=$pretty signal=$line"
      }
    }

    if {[eof $fileptr]} {
      fileevent $fileptr readable {}
      close $fileptr;
      if {$bus == 1} {
        set bus1_state 0
      } else {
        set bus2_state 0
      }
    }
    #elseif {[fblocked $fileptr]}
  }

  ###########################################################################
  # ::DbusViewer::DeInit (dir)                   								#
  # ----------------------------------------------------------------------- #
  # What ??? Someone is unloading me ???									#
  ###########################################################################
  proc DeInit { } {
    global bus1_fileptr
    global bus1_state
    global bus2_fileptr
    global bus2_state
	if {[info exists bus1_state]} {
 	   if {$bus1_state == 1} {
    	  fileevent $bus1_fileptr readable {}
    	  close $bus1_fileptr
    	  set $bus1_state 0
    	}
    }
    if {[info exists bus2_state]} {
    	if {$bus2_state == 1} {
    	  fileevent $bus2_fileptr readable {}
    	  close $bus2_fileptr
    	  set $bus2_state 0
    	}
    }
  }

  ###########################################################################
  # ::DbusViewer::log message               								#
  # ----------------------------------------------------------------------- #
  # Add a log message to plugins-log window  								#
  # Type Alt-P to get that window            								#
  ###########################################################################
  proc log {message} {
    plugins_log DbusViewer $message
  }

  ###########################################################################
  # ::DbusViewer::help		             									#
  # ----------------------------------------------------------------------- #
  # Opens a window with Readme file		 									#
  ###########################################################################
  proc help { } {
    ::amsn::showHelpFileWindow \
      "plugins/DbusViewer/Readme" \
      "DBusViewer Readme"
  }

  ###########################################################################
  # ::DbusViewer::config_array             									#
  # ----------------------------------------------------------------------- #
  # Add config array with default values 									#
  ###########################################################################
  proc config_array {} {
    array set ::DbusViewer::config {
      dbus_cmd_1		{unbuffer dbus-monitor --session}
      dbus_bt_1			{1}
      dbus_cmd_2		{unbuffer dbus-monitor --system}
      dbus_bt_2			{1}
      dbus_bt_match_1	{1}
      dbus_bt_match_2	{1}
      dbus_bt_match_3	{1}
      dbus_bt_match_4	{0}
      dbus_bt_match_5	{0}
      dbus_re_match_1	{member=(.*)}
      dbus_re_match_2	{imap.*INBOX}
      dbus_re_match_3	{imap.*Sent}
      dbus_re_match_4	{}
      dbus_re_match_5	{}
      dbus_bt_fail_1	{1}
      dbus_bt_fail_2	{0}
      dbus_bt_fail_3	{0}
      dbus_bt_fail_4	{0}
      dbus_bt_fail_5	{0}
      dbus_re_fail_1	{member=MessageReading}
      dbus_re_fail_2	{}
      dbus_re_fail_3	{}
      dbus_re_fail_4	{}
      dbus_re_fail_5	{}
      dbus_ignore_res	{1}
    }
  }
  ###########################################################################
  # ::DbusViewer::configlist_values           								#
  # ----------------------------------------------------------------------- #
  # List of items for config window      									#
  ###########################################################################
  proc configlist_values {} {
  set ::DbusViewer::configlist [list \
      [list frame ::DbusViewer::build_config_frame] \
    ]
  }
  proc build_config_frame { w } {
    # Command line for first bus
    frame ${w}.bus1
    label ${w}.bus1.l -text "Configure bus 1"
    checkbutton ${w}.bus1.b -onvalue 1 -offvalue 0 \
            -variable ::DbusViewer::config(dbus_bt_1)
    entry ${w}.bus1.e -textvariable ::DbusViewer::config(dbus_cmd_1) -bg white
    pack ${w}.bus1.l ${w}.bus1.b -side left
    pack ${w}.bus1.e -side left -expand 1 -fill x
    # Command line for second bus
    frame ${w}.bus2
    label ${w}.bus2.l -text "Configure bus 2"
    checkbutton ${w}.bus2.b -onvalue 1 -offvalue 0 \
            -variable ::DbusViewer::config(dbus_bt_2)
    entry ${w}.bus2.e -textvariable ::DbusViewer::config(dbus_cmd_2) -bg white
    pack ${w}.bus2.l ${w}.bus2.b -side left
    pack ${w}.bus2.e -side left -expand 1 -fill x
    pack ${w}.bus1 ${w}.bus2 -expand 1 -fill x
    # Regular expressions
    frame ${w}.res
    # matching REs
    set lf_re_match [LabelFrame::create $w.res.lf_re_match -text "REs that should match"]
    pack $w.res.lf_re_match -side left -expand 1 -fill x -anchor n -pady 10
    frame $lf_re_match.1
    checkbutton $lf_re_match.1.bt_re_match -onvalue 1 -offvalue 0 \
            -variable ::DbusViewer::config(dbus_bt_match_1)
    entry $lf_re_match.1.e_re_match -textvariable ::DbusViewer::config(dbus_re_match_1) -bg white
    pack $lf_re_match.1.bt_re_match -side left
    pack $lf_re_match.1.e_re_match -side left -expand 1 -fill x
    pack $lf_re_match.1 -expand 1 -fill x
    frame $lf_re_match.2
    checkbutton $lf_re_match.2.bt_re_match -onvalue 1 -offvalue 0 \
            -variable ::DbusViewer::config(dbus_bt_match_2)
    entry $lf_re_match.2.e_re_match -textvariable ::DbusViewer::config(dbus_re_match_2) -bg white
    pack $lf_re_match.2.bt_re_match -side left
    pack $lf_re_match.2.e_re_match -side left -expand 1 -fill x
    pack $lf_re_match.2 -expand 1 -fill x
    frame $lf_re_match.3
    checkbutton $lf_re_match.3.bt_re_match -onvalue 1 -offvalue 0 \
            -variable ::DbusViewer::config(dbus_bt_match_3)
    entry $lf_re_match.3.e_re_match -textvariable ::DbusViewer::config(dbus_re_match_3) -bg white
    pack $lf_re_match.3.bt_re_match -side left
    pack $lf_re_match.3.e_re_match -side left -expand 1 -fill x
    pack $lf_re_match.3 -expand 1 -fill x
    frame $lf_re_match.4
    checkbutton $lf_re_match.4.bt_re_match -onvalue 1 -offvalue 0 \
            -variable ::DbusViewer::config(dbus_bt_match_4)
    entry $lf_re_match.4.e_re_match -textvariable ::DbusViewer::config(dbus_re_match_4) -bg white
    pack $lf_re_match.4.bt_re_match -side left
    pack $lf_re_match.4.e_re_match -side left -expand 1 -fill x
    pack $lf_re_match.4 -expand 1 -fill x
    frame $lf_re_match.5
    checkbutton $lf_re_match.5.bt_re_match -onvalue 1 -offvalue 0 \
            -variable ::DbusViewer::config(dbus_bt_match_5)
    entry $lf_re_match.5.e_re_match -textvariable ::DbusViewer::config(dbus_re_match_5) -bg white
    pack $lf_re_match.5.bt_re_match -side left
    pack $lf_re_match.5.e_re_match -side left -expand 1 -fill x
    pack $lf_re_match.5 -expand 1 -fill x
    # failing REs
    set lf_re_fail [LabelFrame::create $w.res.lf_re_fail -text "REs that should fail"]
    pack $w.res.lf_re_fail -side left -expand 1 -fill x -anchor n -pady 10
    frame $lf_re_fail.1
    checkbutton $lf_re_fail.1.bt_re_fail -onvalue 1 -offvalue 0 \
            -variable ::DbusViewer::config(dbus_bt_fail_1)
    entry $lf_re_fail.1.e_re_fail -textvariable ::DbusViewer::config(dbus_re_fail_1) -bg white
    pack $lf_re_fail.1.bt_re_fail -side left
    pack $lf_re_fail.1.e_re_fail -side left -expand 1 -fill x
    pack $lf_re_fail.1 -expand 1 -fill x
    frame $lf_re_fail.2
    checkbutton $lf_re_fail.2.bt_re_fail -onvalue 1 -offvalue 0 \
            -variable ::DbusViewer::config(dbus_bt_fail_2)
    entry $lf_re_fail.2.e_re_fail -textvariable ::DbusViewer::config(dbus_re_fail_2) -bg white
    pack $lf_re_fail.2.bt_re_fail -side left
    pack $lf_re_fail.2.e_re_fail -side left -expand 1 -fill x
    pack $lf_re_fail.2 -expand 1 -fill x
    frame $lf_re_fail.3
    checkbutton $lf_re_fail.3.bt_re_fail -onvalue 1 -offvalue 0 \
            -variable ::DbusViewer::config(dbus_bt_fail_3)
    entry $lf_re_fail.3.e_re_fail -textvariable ::DbusViewer::config(dbus_re_fail_3) -bg white
    pack $lf_re_fail.3.bt_re_fail -side left
    pack $lf_re_fail.3.e_re_fail -side left -expand 1 -fill x
    pack $lf_re_fail.3 -expand 1 -fill x
    frame $lf_re_fail.4
    checkbutton $lf_re_fail.4.bt_re_fail -onvalue 1 -offvalue 0 \
            -variable ::DbusViewer::config(dbus_bt_fail_4)
    entry $lf_re_fail.4.e_re_fail -textvariable ::DbusViewer::config(dbus_re_fail_4) -bg white
    pack $lf_re_fail.4.bt_re_fail -side left
    pack $lf_re_fail.4.e_re_fail -side left -expand 1 -fill x
    pack $lf_re_fail.4 -expand 1 -fill x
    frame $lf_re_fail.5
    checkbutton $lf_re_fail.5.bt_re_fail -onvalue 1 -offvalue 0 \
            -variable ::DbusViewer::config(dbus_bt_fail_5)
    entry $lf_re_fail.5.e_re_fail -textvariable ::DbusViewer::config(dbus_re_fail_5) -bg white
    pack $lf_re_fail.5.bt_re_fail -side left
    pack $lf_re_fail.5.e_re_fail -side left -expand 1 -fill x
    pack $lf_re_fail.5 -expand 1 -fill x
    pack ${w}.res -expand 1 -fill x
    # Debugging
    checkbutton ${w}.ignore_res -text "Show all signals" \
      -onvalue 1 -offvalue 0 -variable ::DbusViewer::config(dbus_ignore_res)
    pack ${w}.ignore_res -side left
    # Help button
    button ${w}.help -text "Help" -command ::DbusViewer::help
    pack ${w}.help -side right
  }
}
