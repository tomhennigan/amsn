
# amsn-extras
#   Provides an interface to manipulate extras for amsn, such as installing plugins or skins
#   ::extras::os
#       - Provides a filesystem API to move/copy/delete files and folders.
#       - Also provides decompression routines for the file extensions supported on the host system.

namespace eval ::extras {
    proc init { dir } {
        source [file join $dir os_base.tcl]
        if { [OnMac] } {
            source [file join $dir os_mac.tcl]
        }
    }
    
    proc install { file_path } {
        return [after 0 [list [namespace current]::installAsync $file_path]]
    }
    
    proc installAsync { file_path } {
        # Sanity check.
        if {![file exists $file_path]} {
            return 0
        }
        
        # Original archive should be deleted.
        # Archive, decompress before testing for plugin/skin
        set extns $::extras::os::supportedCompressedExtensions
        
        #set temp_dir ""
        #if {[file isfile $file_path]} {
        #    set temp_dir [::extras::os::tempdir]
        #    ::extras::os::copyFile $file_path $temp_dir
        #    set file_path [file join $temp_dir [lindex [file split $file_path] end]]
        #}
        
        while {![file isdirectory $file_path]} {
            set file_path [::extras::os::decompress $file_path]
            if { $file_path == "" } {
                status_log "::extras::install: error decompressing file" red
                return 0
            }
        }
        
        if {![file exists $file_path]} {
            # The arcive was decompressed, but we can't find the unarchive dir.
            # The user should be notified that they can retry by installing the now decompressed folder.
            status_log "::extras::install: error finding correctly decompressed archive ($file_path)" red
            return 0
        }
        
        # We have a folder! So now detect skin or plugin, and install it!
        set sop [testSkinOrPlugin $file_path]
        
        if { $sop == "invalid" } {
            # Err, what are you doing!?
            status_log "::extras::install: invalid pluign or skin file" red
            return 0
        }
        
        # IE. ~/.amsn
        set install_base [::extras::os::getaMSNDir]
        
        if { $sop == "skin" } {
            # ~/.amsn/skins
            set install_base [file join $install_base skins]
        } elseif { $sop == "plugin" } {
            # ~/.amsn/plugins
            set install_base [file join $install_base plugins]
        } else {
            status_log "::extras::install: unhandled known type $sop \[shouldn't happen?!\]"
            return 0
        }
        
        # Performs the actual install.
        if {[catch {
            status_log "::extras::install: installing $sop into $install_base"
            [namespace current]::os::moveFolder $file_path $install_base
        } err]} {
            status_log "::extras::install error: $err" red
            return 0
        }
        
        return 1
    }
    
    # @return (string){skin|plugin|invalid}
    proc testSkinOrPlugin { folder_path } {
        # Tests should be a list of tests to validate a particular type.
        # Each test should be a subcommand of file (IE. isfile) followed by the file to test
        set tests [list \
            skin [list isfile settings.xml isdirectory pixmaps] \
            plugin [list isfile plugininfo.xml] \
        ]
        
        # Test each type.
        foreach {type file_tests} $tests {
            set r 1
            foreach {test file} $file_tests {
                if {![file $test [file join $folder_path $file]]} {
                    set r 0
                    break
                }
            }
            if { $r == 1 } {
                return $type
            }
        }
        
        return "invalid"
    }
}
