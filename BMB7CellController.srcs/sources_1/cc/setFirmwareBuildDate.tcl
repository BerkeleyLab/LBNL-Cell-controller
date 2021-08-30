#
# Get time from epoch in UTC.
#

set firmwareDateFile [open "../../BMB7CellController.srcs/sources_1/cc/firmwareBuildDate.v" w]
puts $firmwareDateFile "// MACHINE GENERATED -- DO NOT EDIT"
puts $firmwareDateFile "parameter FIRMWARE_BUILD_DATE = [clock seconds];"
close $firmwareDateFile
