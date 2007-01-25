require_snack

namespace eval ::audio {
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
	proc init { {inputDevice "1"} {outputDevice "1"} {mixerDevice "1"} {volume "1"} {inputGain "1"} {outputGain "1"} } {
		if { $inputDevice } {
			if { [::config::getKey snackInputDevice ""] == "" } {
				::config::setKey snackInputDevice [lindex [snack::audio inputDevices] 0]
			}
		}
		if { $outputDevice } {
			if { [::config::getKey snackOutputDevice ""] == "" } {
				::config::setKey snackOutputDevice [lindex [snack::audio outputDevices] 0]
			}
		}
		if { $mixerDevice } {
			if { [::config::getKey snackMixerDevice ""] == "" } {
				::config::setKey snackMixerDevice [lindex [snack::mixer devices] 0]
			}
		}
		if { $volume } {
			if { [::config::getKey snackMixerVolume ""] == "" } {
				getVolume
			}
		}
		if { $inputGain } {
			if { [::config::getKey snackInputGain ""] == ""} {
				inputGain
			}
		}
		if { $outputGain } {
			if { [::config::getKey snackOutputGain ""] == ""} {
				outputGain
			}
		}
		return
	}
	
	################################################################
	#	::audio::inputDevices()
	# 	Return:
	#		Normal => (list) Avaliable input devices.
	proc inputDevices { } {
		return [snack::audio inputDevices]
	}
	
	################################################################
	#	::audio::inputDevice([fallback ""])
	#	This procedure returns the name of the current input device that is in use.
	#	Arguments:
	#		- fallback => (string) [NOT REQUIRED] The fallback value to return if there is no device set.	
	#	Return:
	#		Normal => (string) Input device name.
	proc inputDevice {{fallback ""}} {
		if { $fallback == "" } {
			set fallback [lindex [snack::audio inputDevices] 0]
		}
		
		return $fallback
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
		if { [lsearch [snack::audio inputDevices] $device] != "-1"  } {
			# The device is avaliable.
			snack::audio selectInput $device
			if {$save} {
				return [::config::setKey snackInputDevice $device]
			} else { return "" }
		} else {
			# The selected device is not avaliable.
			if {[llength [snack::audio inputDevices]] > 0} {
				# If we have devices avaliable default to the first one.
				snack::audio selectInput [lindex [snack::audio inputDevices] 0]
				if {$save} {
					return [::config::setKey snackInputDevice [lindex [snack::audio inputDevices] 0]]
				} else { return "" }
			} else {
				# We have no devices avaliable, return an empty string.
				return ""
			}
		}
	}
	
	################################################################
	#	::audio::inputGain()
	#	This procedure returns the gain on the input device.
	#	Return:
	#		Normal => (int) The gain on the input device. (Range 0-100).
	proc inputGain { } {
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
			snack::audio record_gain 0
		} elseif { $gain > 100 } {
			snack::audio record_gain 100
		} else {
			snack::audio record_gain $gain
		}
		
		if {$save} {
			return [::config::setKey snackInputGain [snack::audio record_gain]]
		} else { return "" }
	}
	
	################################################################
	#	::audio::outputDevices()
	# 	Return:
	#		Normal => (list) Avaliable output devices.
	proc outputDevices { } {
		return [snack::audio outputDevices]
	}
	
	################################################################
	#	::audio::outputDevice([fallback])
	#	This procedure returns the name of the current output device that is in use.
	#	Arguments:
	#		- fallback => (string) [NOT REQUIRED] The fallback value to return if there is no device set.	
	#	Return:
	#		Normal => (string) Output device name.
	proc outputDevice {{fallback ""}} {
		if { $fallback == "" } {
			set fallback [lindex [snack::audio outputDevices] 0]
		}
		
		return $fallback
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
		if { [lsearch [snack::audio outputDevices] $device] != "-1"  } {
			# The device is avaliable.
			snack::audio selectOutput $device
			if {$save} {
				return [::config::setKey snackOutputDevice $device]
			} else { return "" }
		} else {
			# The selected device is not avaliable.
			if {[llength [snack::audio outputDevices]] > 0} {
				# If we have devices avaliable default to the first one.
				snack::audio selectOutput [lindex [snack::audio outputDevices] 0]
				if {$save} {
					return [::config::setKey snackOutputDevice [lindex [snack::audio outputDevices] 0]]
				} else { return "" }
			} else {
				# Otherwise return an empty string.
				return ""
			}
		}
	}
	
	################################################################
	#	::audio::outputGain()
	#	This procedure returns the gain set on the output device.
	#	Return:
	#		Normal => (int) The gain on the output device. (Range 0-100).
	proc outputGain { } {
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
			snack::audio play_gain 0
		} elseif { $gain > 100 } {
			snack::audio play_gain 100
		} else {
			snack::audio play_gain $gain
		}
		
		if {$save} {
			return [::config::setKey snackOutputGain [snack::audio play_gain]]
		} else { return "" }
	}
	
	################################################################
	#	::audio::mixerDevices()
	#	This proc lists all the mixer devcices avaliable to snack.
	# 	Return:
	#		Normal => (list) Avaliable mixers.
	proc mixerDevices { } {
		return [snack::mixer devices]
	}
	
	################################################################
	#	::audio::mixerDevice([fallback ""])
	#	This procedure returns the name of the current mixer that is in use.
	#	If no mixer is set it sets the mixer to $fallback.
	#	Arguments:
	#		- fallback => (string) [NOT REQUIRED] The fallback value to return if there is no device set.	
	#	Return:
	#		Normal => (string) Mixer name.
	proc mixerDevice {{fallback ""}} {
		if { $fallback == "" } {
			set fallback [lindex [snack::mixer devices] 0]
		}
		
		return $fallback
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
		if { [lsearch [snack::mixer devices] $device] != "-1"  } {
			# The mixer is avaliable.
			snack::mixer select $device
			if {$save} {
				return [::config::setKey snackMixerDevice $device]
			} else { return "" }
		} else {
			# The selected mixer is not avaliable.
			if {[llength [snack::mixer devices]] > 0} {
				# If we have mixers avaliable default to the first one.
				snack::mixer select [lindex [snack::mixer devices] 0]
				if {$save} {
					return [::config::setKey snackMixerDevice [lindex [snack::mixer devices] 0]]
				} else { return "" }
			} else {
				# Otherwise return an empty string.
				return ""
			}
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
		set mixDev [::audio::mixerDevice]
		if {$line == "" } {
			set line [lindex [snack::mixer lines] 0]
		}
		
		return [snack::mixer volume $line]
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
	proc setVolume { volume {save 1} { line "" } } {
		
		if { [llength [snack::mixer lines]] == "0" } {
			# We have no input lines. (Bad setup).
			return ""
		}
		
		if { $line == "" || [lsearch [snack::mixer lines] $line] == "-1" } {
			# The line chosen doesn't exist, so use the first one avaliable.
			set line [lindex [snack::mixer lines] 0]
		}
		
		set vol $volume
		if {[snack::mixer channels $line] == "Mono"} {
			snack::mixer volume $line vol
		} else {
			snack::mixer volume $line $vol $vol
		}
		if {$save} {
			return [::config::setKey snackMixerVolume [snack::mixer volume $line]]
		} else { return "" }
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
		::config::setKey snackInputGain ""
		::config::setKey snackOutputGain ""
		::config::setKey snackMixerVolume ""
		return
	}
}
