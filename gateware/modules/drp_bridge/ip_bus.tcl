# add a bus for all DRP interfaces
for {set i 0} {$i < 32} {incr i} {
    dict set ip_bus DRP${i} bus_type "drp_rtl"
    dict set ip_bus DRP${i} mode "master"
    dict set ip_bus DRP${i} port_maps \
    [list \
        [list drp${i}_en   den] \
        [list drp${i}_we   dwe] \
        [list drp${i}_addr daddr] \
        [list drp${i}_di   di] \
        [list drp${i}_do   do] \
        [list drp${i}_rdy  drdy] \
    ]
}
