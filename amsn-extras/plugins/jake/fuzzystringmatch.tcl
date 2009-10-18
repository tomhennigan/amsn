proc stringDistance {a b} {
    set n [string length $a]
    set m [string length $b]
    for {set i 0} {$i<=$n} {incr i} {set c($i,0) $i}
    for {set j 0} {$j<=$m} {incr j} {set c(0,$j) $j}
    for {set i 1} {$i<=$n} {incr i} {
        for {set j 1} {$j<=$m} {incr j} {
            set x [expr {$c([- $i 1],$j)+1}]
            set y [expr {$c($i,[- $j 1])+1}]
            set z $c([- $i 1],[- $j 1])
            if {[string index $a [- $i 1]]!=[string index $b [- $j 1]]} {
                incr z
            }
            set c($i,$j) [min $x $y $z]
        }
    }
    set c($n,$m)
}

if {[catch {
        package require Tcl 8.5
        namespace path {tcl::mathfunc tcl::mathop}
        }]} then {
        proc min args {lindex [lsort -real $args] 0}
        proc max args {lindex [lsort -real $args] end}
        proc - {p q} {expr {$p-$q}}
}

proc stringSimilarity {a b} {
        set totalLength [string length $a$b]
        max [expr {double($totalLength-2*[stringDistance $a $b])/$totalLength}] 0.0
}