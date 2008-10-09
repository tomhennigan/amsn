
namespace eval ::extras::os {
    set ::extras::os::supportedCompressedExtensions [list]
    
    # Returns the path to the folder in which to install the plugins and skins. IE. ~/.amsn on linux
    proc getaMSNDir {}  {
        return "~/.amsn"
    }
    
    # Should NOT be recursive to work with multiple levels of compression, IE. tar.gz
    # This will be handled by ::extras
    # Decompression routines  should be defined as:
    #   proc decompress.extension { compressed_file } { return decompressed_file or "" }
    # @return: (string)path_to_folder or "" if not successful
    proc decompress { file_path } {        
        set ext [file extension $file_path]
        if {![file exists $file_path]} {
            return ""
        }
        
        if {[file isdirectory $file_path]} {
            return $file_path
        }
        
        if {[lsearch $::extras::os::supportedCompressedExtensions $ext] == -1} {
            ::extras::log "extension ($ext) not supported" warning
            return ""
        }
        
        ::extras::log "decompressing $ext file $file_path"
        
        if {[catch {
            set file_path [decompress${ext} $file_path]
        } res]} {
            ::extras::log "couldn't decompress ($ext): $res" error
            set file_path ""
        }
        
        return $file_path
    }
    
    # Functions to move files around.
    proc copyFile { old_file new_file } {
        file copy -force -- $old_file $new_file
    }
    proc moveFile { old_file new_file } {
        copyFile $old_file $new_file
        deleteFile $old_file
    }
    # @return: (bool)success
    proc deleteFile { file_path } {
        if {[file exists $file_path]} {
            file delete -- $file_path
        }
    }
    
    # Functions to move folders around.
    proc copyFolder { old_folder new_parent } {
        copyFile $old_folder $new_parent
        deleteFolder $old_folder
    }
    proc moveFolder { old_folder new_parent } {
        deleteFolder [file join $new_parent [lindex [file split $old_folder] end]]
        copyFolder $old_folder $new_parent
        deleteFolder $old_folder
    }
    # @return: (bool)success
    proc deleteFolder { folder_path } {
        if {[file exists $folder_path]} {
            file delete -force -- $folder_path
        }
    }
    
    # Functions to make temporary writable files and folders.
    # @return: (string)path to temp folder
    proc tempdir {} { return "" }
    # @return: (string)path to temp file
    proc tempfile {} { return "" }
}
