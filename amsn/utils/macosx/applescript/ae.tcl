#Here we add the code to make aMSN accept AppleEvent from "Do Script" command in AppleScript
#Thanks to Jon Guyer	
package require tclAE

tclAE::installEventHandler misc dosc handleDoScript
tclAE::aete::register constructAETE

proc handleDoScript {theAppleEvent theReplyAE} {
    set scriptDesc [tclAE::getKeyDesc $theAppleEvent ----]
    set type [tclAE::getDescType $scriptDesc]

    switch -- $type {
        "TEXT" -
        "utxt" -
        "STXT" {
            eval [tclAE::getData $scriptDesc utxt]
        }
        "alis" {
            source [tclAE::getData $scriptDesc TEXT]
        }
        default {
            set errn -1770
            set errs "AEDoScriptHandler: invalid script type '${type}', \
              must be 'alis', 'TEXT', 'utxt', or 'STXT'"
            status::msg $errs

            tclAE::putKeyData $theReplyAE errs TEXT $errs
            tclAE::putKeyData $theReplyAE errn long $errn

            return $errn
        }
    }
}

proc constructAETE {} {
    set events {}
    set enumerations {}
    set enumerators {}

    lappend enumerators [list "Tcl instructions" utxt "Tcl script code to execute"]
    lappend enumerators [list "alias" alis "alias of a .tcl script file to source"]

    lappend enumerations [list ScAl $enumerators]

    lappend events [list "my do script" \
      "Execute a Tcl (Tool Command Language) script" misc dosc \
      {null "" 000} {ScAl "the Tcl script to execute" 0011}]

    lappend suites [list "Miscellaneous Standards Suite" \
      "Useful events that aren't in any other suite." \
      misc 1 1 $events {} {} $enumerations]

    return [list 1 0 0 0 $suites]
}

