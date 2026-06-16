if { $argc < 4 } {
    puts "Not enough arguments"
    puts "Usage: vivado -mode batch -nojou -nolog -source bd_proc.tcl gen_bd_tcl.tcl -tclargs <bd_tcl_file> <project_part> <project_board> <ipcore_dirs>"
    exit
}

set bd_tcl_file [file normalize [lindex $argv 0]]
set project_part [lindex $argv 1]
set project_board [lindex $argv 2]
set ipcore_dirs [lrange $argv 3 end]

gen_bd_tcl $bd_tcl_file $project_part $project_board $ipcore_dirs
