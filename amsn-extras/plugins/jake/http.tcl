#amsn has package http 2.4.4, so, provide the 2.5.5 version of http::formatQuery
for {set i 0} {$i <= 256} {incr i} {
    set c [format %c $i]
    if {![string match {[-._~a-zA-Z0-9]} $c]} {
        set map($c) %[format %.2x $i]
    }
}
set map(\n) %0d%0a
variable formMap [array get map]
variable http
array set http {
    -accept */*
    -proxyhost {}
    -proxyport {}
    -proxyfilter http::ProxyRequired
    -urlencoding utf-8
}

proc httpformatQuery {args} {
    set result ""
    set sep ""
    foreach i $args {
        append result $sep [mapReply $i]
        if {$sep eq "="} {
            set sep &
        } else {
            set sep =
        }
    }
    return $result
}

proc mapReply {string} {
    variable http
    variable formMap

    if {$http(-urlencoding) ne ""} {
        set string [encoding convertto $http(-urlencoding) $string]
        return [string map $formMap $string]
    }
    set converted [string map $formMap $string]
    if {[string match "*\[\u0100-\uffff\]*" $converted]} {
        regexp {[\u0100-\uffff]} $converted badChar
        # Return this error message for maximum compatability... :^/
        return -code error \
            "can't read \"formMap($badChar)\": no such element in array"
    }
    return $converted
}