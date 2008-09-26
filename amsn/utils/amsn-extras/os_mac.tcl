
# todo:
#   - add zip handler
#   - fix return name of tar and gz (currently assuming that the return is the same as parent - the extension)

# This handler lets us install documents dropped onto the application's icon in the dock.
proc ::tk::mac::OpenDocument { file } {
 	::extras::install $file
}

namespace eval ::extras::os {
    set ::extras::os::supportedCompressedExtensions [list ".tar" ".gz" ".tgz"]
    
    proc getaMSNDir {} {
        global env
        return [file join $env(HOME) Library "Application Support" amsn]
    }
    
    proc decompress.tgz { file_path } {
        exec tar -C [file dirname $file_path] -xzf $file_path
        deleteFile $file_path
        return [file rootname $file_path]
    }
    proc decompress.tar { file_path } {
        exec tar -C [file dirname $file_path] -xf $file_path
        deleteFile $file_path
        return [file rootname $file_path]
    }
    proc decompress.gz { file_path } {
        exec gzip -d $file_path
        return [file rootname $file_path]
    }
    
    proc tempdir {} {
        return [exec mktemp -d -t amsn-extras]
    }
    proc tempfile {} {
        return [exec mktemp -t amsn-extras]
    }
}
