if {[llength [get_hw_servers]] == 0} { connect_hw_server }
close_hw_target
open_hw_target
current_hw_device [lindex [get_hw_devices] 0]
set_property PROGRAM.FILE {build/out.bit} [lindex [get_hw_devices] 0]
program_hw_devices [lindex [get_hw_devices] 0]
