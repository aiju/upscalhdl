set_property IOSTANDARD LVCMOS33 [get_ports clk]
set_property PACKAGE_PIN N11 [get_ports clk]
set_property IOSTANDARD LVCMOS18 [get_ports led*]
set_property PACKAGE_PIN C16 [get_ports led0]
set_property PACKAGE_PIN D15 [get_ports led1]
set_property PACKAGE_PIN D16 [get_ports led2]
set_property PACKAGE_PIN E16 [get_ports led3]
set_property PACKAGE_PIN P11 [get_ports sda]
set_property IOSTANDARD LVCMOS33 [get_ports sda]
set_property PACKAGE_PIN N13 [get_ports scl]
set_property IOSTANDARD LVCMOS33 [get_ports scl]

set_property IOSTANDARD LVCMOS18 [get_ports hd*]
set_property PACKAGE_PIN B16 [get_ports hdclk]
set_property PACKAGE_PIN B14 [get_ports hdde]
set_property PACKAGE_PIN B15 [get_ports hdvs]
set_property PACKAGE_PIN A15 [get_ports hdhs]
set_property PACKAGE_PIN A14 [get_ports {hddat[0]}]
set_property PACKAGE_PIN A13 [get_ports {hddat[1]}]
set_property PACKAGE_PIN B12 [get_ports {hddat[2]}]
set_property PACKAGE_PIN A12 [get_ports {hddat[3]}]
set_property PACKAGE_PIN B11 [get_ports {hddat[4]}]
set_property PACKAGE_PIN B10 [get_ports {hddat[5]}]
set_property PACKAGE_PIN A10 [get_ports {hddat[6]}]
set_property PACKAGE_PIN B9 [get_ports {hddat[7]}]
set_property PACKAGE_PIN A9 [get_ports {hddat[8]}]
set_property PACKAGE_PIN C8 [get_ports {hddat[9]}]
set_property PACKAGE_PIN A8 [get_ports {hddat[10]}]
set_property PACKAGE_PIN D8 [get_ports {hddat[11]}]
set_property PACKAGE_PIN C11 [get_ports hdmclk]
set_property PACKAGE_PIN C13 [get_ports hdsclk]
set_property PACKAGE_PIN C14 [get_ports hdlrclk]
set_property PACKAGE_PIN C12 [get_ports hdi2s]
set_property PACKAGE_PIN D14 [get_ports hdint]

set_property IOSTANDARD LVCMOS33 [get_ports ext*]
set_property PACKAGE_PIN R2 [get_ports {ext[0]}]
set_property PACKAGE_PIN P4 [get_ports {ext[1]}]
set_property PACKAGE_PIN R1 [get_ports {ext[2]}]
set_property PACKAGE_PIN M5 [get_ports {ext[3]}]
set_property PACKAGE_PIN P1 [get_ports {ext[4]}]
set_property PACKAGE_PIN N4 [get_ports {ext[5]}]
set_property PACKAGE_PIN N2 [get_ports {ext[6]}]
set_property PACKAGE_PIN N3 [get_ports {ext[7]}]
set_property PACKAGE_PIN N1 [get_ports {ext[8]}]
set_property PACKAGE_PIN M4 [get_ports {ext[9]}]
set_property PACKAGE_PIN M2 [get_ports {ext[10]}]
set_property PACKAGE_PIN M1 [get_ports {ext[11]}]

set_property IOSTANDARD LVCMOS33 [get_ports adreset]
set_property PACKAGE_PIN P14 [get_ports adreset]

create_clock -name clk -period 10.000 [get_nets clk]
create_clock -name hdclk -period 13.158 [get_nets hdclk]


set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.UNUSEDPIN PULLUP [current_design]
