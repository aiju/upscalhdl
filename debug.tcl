proc bitrev {n} {
	string reverse [string map {0 0 1 8 2 4 3 c 4 2 5 a 6 6 7 e 8 1 9 9 a 5 b d c 3 d b e 7 f f} $n]
}

proc reg {addr {val 0}} {
	bitrev [string range [scan_dr_hw_jtag -tdi [format "%s%s" [bitrev [format "%.4x" 0x$val]] [bitrev [format "%.4x" 0x$addr]]] 32] 0 3]
}

proc arm {} {
	reg ff01
}

proc wait {} {
	while {[reg ff00] != 0000} {}
}

proc readdata {} {
	set N [expr 0x[reg ff02]]
	set M [expr 0x[reg ff03]]
	set NR [expr $N + 15 & -16]
	set s [string range [bitrev [scan_dr_hw_jtag -tdi 0000 [expr $NR * $M + 16]]] 4 end]
	set fp [open "dump" w]
	for {set i 0} {$i < [string length $s]} {incr i [expr {$NR / 4}]} {puts $fp [string range $s $i [expr {$i + $NR / 4 - 1}]]}
	close $fp
}

close_hw_target
open_hw_target -jtag_mode on
scan_ir_hw_jtag -tdi 2 6

arm
wait
readdata
