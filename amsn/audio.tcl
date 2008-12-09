
::Version::setSubversionId {$Id$}

# This needs to be done this way because it seems Mac shows an error about conflicting versions if you have 2.2 and 2.2.10 installed...
# but on linux (and windows) it takes the latest version (2.2.10) without complaining...
# Since Mac and Windows have the snack 2.2.10 binaries shipped with amsn,we can require the exact version safely.. linux is trickier because
# the user can install whatever version he wants (and all 2.2.x versions have a 'package provide 2.2')
proc require_snack { } {
	if {[package provide snack] != ""} {
		return
	}  elseif {[OnWin] } {
		if { [catch {
			load [file join utils windows snack2.2 libsnack.dll]
			source [file join utils windows snack2.2 snack.tcl]
		} ] } {
			package require snack 
		}
	} elseif {[OnMac] } {
		if { [catch {
			package require snack 
		} ] } {
			if {[file exists [file join utils macosx snack2.2 [info tclversion] libsnack.dylib]]} {
				load [file join utils macosx snack2.2 [info tclversion] libsnack.dylib]
			} else {
				load [file join utils macosx snack2.2 libsnack.dylib]
			}
			source [file join utils macosx snack2.2 snack.tcl]
		}
	} else {
		package require snack
	}
	
	# If snack didn't get loaded, then an error would have been thrown out and we wouldn't be here setting SnackSettings...
	::audio::init 
}



namespace eval ::audio {
	variable inputDevice
	variable outputDevice
	variable mixerDevice

	################################################################
	#	::audio::init()
	#	This procedure initialises aMSN's audio settings.
	#	Arguments:
	#		- inputDevice => (bool) [NOT REQUIRED] Initialise the inputDevice.
	#		- outputDevice => (bool) [NOT REQUIRED] Initialise the outputDevice.	
	#		- mixerDevice => (bool) [NOT REQUIRED] Initialise the mixerDevice.
	#		- volume => (bool) [NOT REQUIRED] Initialise the volume.
	#		- inputGain => (bool) [NOT REQUIRED] Initialise the inputGain.
	#		- outputGain => (bool) [NOT REQUIRED] Initialise the outputGain.
	#	Return:
	#		Normal => (bool) True.
	proc init { {inputDevice_b "1"} {outputDevice_b "1"} {mixerDevice_b "1"} } {
		variable inputDevice
		variable outputDevice
		variable mixerDevice

		# just to make sure snack is loaded.. if it was already loaded then the first check of require_snack will return immediatly 
		# (avoiding a recursive loop). If snack is not loaded, we return.
		if { [catch {require_snack}] } {
			return
		}

		if { $inputDevice_b } {
			if { [::config::getKey snackInputDevice ""] == "" } {
				::config::setKey snackInputDevice [lindex [getInputDevices] 0]
			}
			setInputDevice [::config::getKey snackInputDevice]
		}
	
		if { $outputDevice_b } {
			if { [::config::getKey snackOutputDevice ""] == "" } {
				::config::setKey snackOutputDevice [lindex [getOutputDevices] 0]
			}
			setOutputDevice [::config::getKey snackOutputDevice]
		}
		
		if { $mixerDevice_b } {
			if { [::config::getKey snackMixerDevice ""] == "" } {
				::config::setKey snackMixerDevice [lindex [getMixerDevices] 0]
			}
			setMixerDevice [::config::getKey snackMixerDevice]
		}
	
		# legacy, it seems like it's needed to avoid gaps in the sound... 
		::snack::audio playLatency 750

		return
	}
	
	################################################################
	#	::audio::getInputDevices()
	# 	Return:
	#		Normal => (list) Avaliable input devices.
	proc getInputDevices { } {
		return [snack::audio inputDevices]
	}
	
	################################################################
	#	::audio::getInputDevice([fallback ""])
	#	This procedure returns the name of the current input device that is in use.
	#	Arguments:
	#		- fallback => (string) [NOT REQUIRED] The fallback value to return if there is no device set.	
	#	Return:
	#		Normal => (string) Input device name.
	proc getInputDevice {{fallback ""}} {
		variable inputDevice
		if {[info exists inputDevice]} {
			return $inputDevice
		} else {
		
			if { $fallback == "" } {
				set fallback [lindex [getInputDevices] 0]
			}
			return [setInputDevice [config::getKey snackInputDevice $fallback]]
		}
	}

	################################################################
	#	::audio::setInputDevice(device, [save])
	#	This procedure sets the input device used by snack.
	#	Arguements:
	#		- device => (string) The name of the device to set.
	#		- save => (boolean) [NOT REQUIRED] save the setting in config
	#	Return:
	#		Normal => (sting) Input device name.
	#		Error	 => (string) ""
	proc setInputDevice {device {save 1}} {
		variable inputDevice

		if { [lsearch -exact [getInputDevices] $device] != -1  } {
			# The device is avaliable.
			if { ![catch {snack::audio selectInput $device} ] } {
				set inputDevice $device
				if {$save} {
					::config::setKey snackInputDevice $device
				}
				return $device
			}
		} 

		# The selected device is not avaliable.
		if {[llength [getInputDevices]] > 0} {
			# If we have devices avaliable default to the first one.
			snack::audio selectInput [lindex [getInputDevices] 0]
			if {$save} {
				return [::config::setKey snackInputDevice [lindex [getInputDevices] 0]]
			} else { 
				return "" 
			}
		} else {
			# We have no devices avaliable, return an empty string.
			return ""
		}
	}
	
	################################################################
	#	::audio::getInputGain()
	#	This procedure returns the gain on the input device.
	#	Return:
	#		Normal => (int) The gain on the input device. (Range 0-100).
	proc getInputGain { } {
		return [snack::audio record_gain]
	}
	
	################################################################
	# ::audio::setInputGain(gain, [save])
	#	Parameters:
	#		- gain => (int) The gain factor to set on the input device. (Range 0-100).
	#		- save => (boolean) [NOT REQUIRED] save the setting in config
	#	Return
	#		Normal => (int) The gain set on the input device.
	proc setInputGain { gain {save 1} } {
		if { $gain < 0 } {
			set gain 0
		} elseif { $gain > 100 } {
			set gain 100
		}
		
		snack::audio record_gain $gain
		
		return [getInputGain]
	}
	
	################################################################
	#	::audio::getOutputDevices()
	# 	Return:
	#		Normal => (list) Avaliable output devices.
	proc getOutputDevices { } {
		return [snack::audio outputDevices]
	}
	
	################################################################
	#	::audio::outputDevice([fallback])
	#	This procedure returns the name of the current output device that is in use.
	#	Arguments:
	#		- fallback => (string) [NOT REQUIRED] The fallback value to return if there is no device set.	
	#	Return:
	#		Normal => (string) Output device name.
	proc getOutputDevice {{fallback ""}} {
		variable outputDevice
		if {[info exists outputDevice]} {
			return $outputDevice
		} else {
			if { $fallback == "" } {
				set fallback [lindex [getOutputDevices] 0]
			}
			return [setOutputDevice [config::getKey snackOutputDevice $fallback]]
		}
	}
	
	################################################################
	#	::audio::setOutputDevice(device, [save])
	#	This procedure sets the output device used by snack.
	#	Arguments:
	#		- device => (string) The name of the device to change to.
	#		- save => (boolean) [NOT REQUIRED] save the setting in config
	#	Return:
	#		Normal => (sting) Output device name.
	#		Error	 => (string) ""
	proc setOutputDevice {device {save 1 }} {
		variable outputDevice

		if { [lsearch -exact [getOutputDevices] $device] != -1  } {
			# The device is avaliable.
			if { ![catch {snack::audio selectOutput $device} ] } {
				set outputDevice $device
				if {$save} {
					::config::setKey snackOutputDevice $device
				} 
				return $device
			}
		} 

		# The selected device is not avaliable.
		if {[llength [getOutputDevices]] > 0} {
			# If we have devices avaliable default to the first one.
			snack::audio selectOutput [lindex [getOutputDevices] 0]
			if {$save} {
				return [::config::setKey snackOutputDevice [lindex [getOutputDevices] 0]]
			} else { 
				return "" 
			}
		} else {
			# Otherwise return an empty string.
			return ""
		}
	}
	
	################################################################
	#	::audio::outputGain()
	#	This procedure returns the gain set on the output device.
	#	Return:
	#		Normal => (int) The gain on the output device. (Range 0-100).
	proc getOutputGain { } {
		return [snack::audio play_gain]
	}
	
	################################################################
	#	::audio::setOutputGain(gain, [save])
	#	Parameters:
	#		- gain => (int) The gain factor to set on the input device. (Range 0-100).
	#		- save => (boolean) [NOT REQUIRED] save the setting in config
	#	Return
	#		Normal => (int) The gain set on the device.
	proc setOutputGain { gain {save 1}} {
		if { $gain < 0 } {
			set gain 0
		} elseif { $gain > 100 } {
			set gain 100
		} 
			
		snack::audio play_gain $gain
		
		return [getOutputGain]
		
	}
	
	################################################################
	#	::audio::getMixerDevices()
	#	This proc lists all the mixer devcices avaliable to snack.
	# 	Return:
	#		Normal => (list) Avaliable mixers.
	proc getMixerDevices { } {
		return [snack::mixer devices]
	}
	
	################################################################
	#	::audio::getMixerDevice([fallback ""])
	#	This procedure returns the name of the current mixer that is in use.
	#	If no mixer is set it sets the mixer to $fallback.
	#	Arguments:
	#		- fallback => (string) [NOT REQUIRED] The fallback value to return if there is no device set.	
	#	Return:
	#		Normal => (string) Mixer name.
	proc getMixerDevice {{fallback ""}} {
		variable mixerDevice
		if {[info exists mixerDevice]} {
			return $mixerDevice
		} else {
			if { $fallback == "" } {
				set fallback [lindex [getMixerDevices] 0]
			}
			return [setMixerDevice [config::getKey snackMixerDevice $fallback]]
		}
	}
	
	################################################################
	#	::audio::setMixerDevice(device, [save])
	#	This procedure sets the mixer used by snack.
	#	Arguements:
	#		- device => (string) The name of the mixer device to use.
	#		- save => (boolean) [NOT REQUIRED] save the setting in config
	#	Return:
	#		Normal => (sting) Mixer name.
	#		Error	 => (string) ""
	proc setMixerDevice { device {save 1} } {
		variable mixerDevice

		if { [lsearch -exact [getMixerDevices] $device] != "-1"  } {
			# The mixer is avaliable.
			if { ![catch { snack::mixer select $device } ] } {
				set mixerDevice $device
				if {$save} {
					::config::setKey snackMixerDevice $device
				}
				return $device
			}
		} 

		# The selected mixer is not avaliable.
		if {[llength [getMixerDevices]] > 0} {
			# If we have mixers avaliable default to the first one.
			snack::mixer select [lindex [getMixerDevices] 0]
			if {$save} {
				return [::config::setKey snackMixerDevice [lindex [getMixerDevices] 0]]
			} else { 
				return "" 
			}
		} else {
			# Otherwise return an empty string.
			return ""
		}
	}
	
	################################################################
	#	::audio::getVolume()
	#	This procedure returns the volume of the mixer we are currently using.
	#	This equalises the volume for stereo devices to ensure both are at the same level.
	#	Arguments:
	#		- line => (string) [NOT REQUIRED] The output line for the device.
	#	Return:
	#		Normal	=> (int) Volume.
	proc getVolume {{line ""}} {
		# the following line is just to make sure the appropriate mixer was selected
		::audio::getMixerDevice
		
		if {$line == "" } {
			set line [lindex [snack::mixer lines] 0]
		}
		
		set ret [snack::mixer volume $line]
		#snack returns sometimes weird results
		if {![string is integer -strict $ret]} {
			set ret 0
		}
		return $ret
	}
	
	################################################################
	#	::audio::setVolume(volume, [save], [line])
	#	This procedure sets snack's internal volume.
	#	Arguments:
	#		- volume => (int) The playback volume to set on the mixer. (Range 0-100)
	#		- save => (boolean) [NOT REQUIRED] save the setting in config
	#		- line => (string) [NOT REQUIRED] The output line (default=[lindex [snack::mixer lines] 0]).
	#	Return:
	#		Normal => (int) Volume
	#		Error	 => (int) Volume
	proc setVolume { volume { line "" } } {

		# the following line is just to make sure the appropriate mixer was selected
		::audio::getMixerDevice
		
		if { [llength [snack::mixer lines]] == "0" } {
			# We have no input lines. (Bad setup).
			return ""
		}
		
		if { $line == "" || [lsearch -exact [snack::mixer lines] $line] == "-1" } {
			# The line chosen doesn't exist, so use the first one avaliable.
			set line [lindex [snack::mixer lines] 0]
		}
		

		# This damn crappy thing is crap! you can't 'set' the volume, you can just link it to a variable, then you change that variable's value to change the volume!! interesting though...
		set ::audio::volume_$line $volume
		if {[snack::mixer channels $line] == "Mono"} {
			snack::mixer volume $line ::audio::volume_$line
		} else {
			snack::mixer volume $line ::audio::volume_$line ::audio::volume_$line
		}
		
		
		return [getVolume $line]
		
	}
	
	################################################################
	#	::audio::clearConfig()
	#	This procedure clears the config that we've set.
	#	Return:
	#		Normal => (bool) True
	proc clearConfig {} {
		::config::setKey snackInputDevice ""
		::config::setKey snackOutputDevice ""
		::config::setKey snackMixerDevice ""
	}
}


catch {require_snack}
