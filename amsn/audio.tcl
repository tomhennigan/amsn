
::Version::setSubversionId {$Id$}

catch {require_snack}

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
	proc init { {inputDevice_b "1"} {outputDevice_b "1"} {mixerDevice_b "1"} {volume_b "1"} {inputGain_b "1"} {outputGain_b "1"} } {
		variable inputDevice
		variable outputDevice
		variable mixerDevice

		if { $inputDevice_b } {
			if { [::config::getKey snackInputDevice ""] == "" } {
				::config::setKey snackInputDevice [lindex [snack::audio inputDevices] 0]
			}
			set inputDevice [::config::getKey snackInputDevice]
		}
	
		if { $outputDevice_b } {
			if { [::config::getKey snackOutputDevice ""] == "" } {
				::config::setKey snackOutputDevice [lindex [snack::audio outputDevices] 0]
			}
			set outputDevice [::config::getKey snackOutputDevice]
		}
		
		if { $mixerDevice_b } {
			if { [::config::getKey snackMixerDevice ""] == "" } {
				::config::setKey snackMixerDevice [lindex [snack::mixer devices] 0]
			}
			set mixerDevice [::config::getKey snackMixerDevice]
		}
	
		if { $volume_b } {
			if { [::config::getKey snackMixerVolume ""] == "" } {
				::config::setKey snackMixerVolume [getVolume]
			}
		}

		if { $inputGain_b } {
			if { [::config::getKey snackInputGain ""] == ""} {
				::config::setKey snackInputGain [inputGain]
			}
		}

		if { $outputGain_b } {
			if { [::config::getKey snackOutputGain ""] == ""} {
				::config::setKey snackOutputGain [outputGain]
			}
		}

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
		if { $fallback == "" } {
			set fallback [lindex [snack::audio inputDevices] 0]
		}
		if {[info exists inputDevice]} {
			return $inputDevice
		} else {
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
		if { [lsearch [snack::audio inputDevices] $device] != -1  } {
			# The device is avaliable.
			snack::audio selectInput $device
			set inputDevice $device
			if {$save} {
				::config::setKey snackInputDevice $device
			}
			return $device
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
			snack::audio record_gain 0
		} elseif { $gain > 100 } {
			snack::audio record_gain 100
		} else {
			snack::audio record_gain $gain
		}
		
		if {$save} {
			return [::config::setKey snackInputGain [snack::audio record_gain]]
		} else { return $gain }
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
		if { $fallback == "" } {
			set fallback [lindex [snack::audio outputDevices] 0]
		}
		if {[info exists outputDevice]} {
			return $outputDevice
		} else {
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
		if { [lsearch [snack::audio outputDevices] $device] != -1  } {
			# The device is avaliable.
			snack::audio selectOutput $device
			set outputDevice $device
			if {$save} {
				::config::setKey snackOutputDevice $device
			} 
			return $device
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
		if { $fallback == "" } {
			set fallback [lindex [snack::mixer devices] 0]
		}
		if {[info exists mixerDevice]} {
			return $mixerDevice
		} else {
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
		if { [lsearch [snack::mixer devices] $device] != "-1"  } {
			# The mixer is avaliable.
			snack::mixer select $device
			set mixerDevice $device
			if {$save} {
				::config::setKey snackMixerDevice $device
			}
			return $device
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
		set mixDev [::audio::getMixerDevice]
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
