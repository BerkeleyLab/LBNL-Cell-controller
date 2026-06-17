proc gen_bd_tcl {bd_tcl_file project_part project_board ipcore_dirs} {
    # create_ip requires that a project is open in memory. Create project
    # but don't do anything with it
    create_project -in_memory -part $project_part -force my_project

    # specify board_part if existent
    if {$project_board ne "none"} {
        set_property board_part $project_board [current_project]
    }

    # specify additional library directories for custom IPs
    set_property ip_repo_paths $ipcore_dirs [current_fileset]
    update_ip_catalog -rebuild

    # delete .bd file if it exists. Otherwise Vivado will fail to
    # generate it

    set bd_file "[file rootname ${bd_tcl_file}].bd"

    if {[file exists ${bd_file}]} {
        file delete ${bd_file}
    }

    # set the location of the generated products
    set bd_tcl_file_dir [file dirname [file normalize ${bd_tcl_file}]]
    set bd_tcl_file_parent [file join ${bd_tcl_file_dir} ".."]
    set ::origin_dir_loc ${bd_tcl_file_parent}

    # read an BD file into project
    source $bd_tcl_file

    # Check if variables were set
    if {![info exists str_bd_filepath] || $str_bd_filepath eq ""} {
        catch {common::send_gid_msg -ssname BD::TCL -id 2030 -severity "ERROR" "The remote BD file path <str_bd_filepath> does not exist!"}
        return 1
    }

    # make top level wrapper
    make_wrapper -files [get_files $str_bd_filepath] -top

    # Generate all the output products
    generate_target all [get_files $str_bd_filepath] -force

    # export and validate hardware platform for use with
    # Vitis
    set bd_basename [file rootname [file tail $str_bd_filepath]]
    write_hw_platform -fixed -force $bd_basename.xsa
    validate_hw_platform ./$bd_basename.xsa
}
