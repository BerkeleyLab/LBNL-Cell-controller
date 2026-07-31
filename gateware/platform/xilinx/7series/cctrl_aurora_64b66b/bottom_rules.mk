# clean generate IP cores files, but the source ones (.tcl)
clean::
	$(foreach ipcore, $(cell_controller_IP_CORES), test -f $(cell_controller_7series_platform_app_DIR)/$(ipcore)/$(ipcore).tcl && find $(cell_controller_7series_platform_app_DIR)/$(ipcore) -mindepth 1 -not \( -name \*$(ipcore).tcl -o -name \*.coe \) -delete $(CMD_SEP))
	$(foreach bd, $(cell_controller_BD_CORE), test -f $(cell_controller_7series_platform_app_DIR)/$(bd)/$(bd).tcl && find $(cell_controller_7series_platform_app_DIR)/$(bd) -mindepth 1 -not \( -name \*$(bd).tcl -o -name \*.coe \) -delete $(CMD_SEP))
