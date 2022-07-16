#
# aggregate rules based on ethernet-core rules.mk, but with a specificy UDP_PORT
#
CLIENT_UDP_PORTS = 30721

%aggregate.v: $(CORE_DIR)/agg $(CORE_DIR)/aggregate.vp
	perl $< $(CLIENT_UDP_PORTS) <$(filter %.vp, $^) >$@
