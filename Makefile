TOOLS_CONF ?= tools.yml
TECH_CONF ?= gf55lpx.yml
GENERIC_DESIGN_CONF ?= generic-design.yml
HAMMER_ENV_SPEC ?= env.yml
HAMMER_EXECUTABLE ?= ./gint-vlsi

design_conf_file ?= $(TARGET)-design.yml
build_dir ?= build/$(TARGET)
hammer_extra_mk = $(build_dir)/hammer.d


$(hammer_extra_mk):
	$(HAMMER_EXECUTABLE) -e $(HAMMER_ENV_SPEC) -p $(TOOLS_CONF) -p $(TECH_CONF) -p $(GENERIC_DESIGN_CONF) -p $(design_conf_file) --obj_dir $(build_dir) build
.PHONY buildfile: $(hammer_extra_mk)

include $(hammer_extra_mk)

.PHONY check-syn:
	cd $(build_dir)/syn-rundir; source ./enter; echo "read_db latest" > check-startup.tcl; /ece/cadence/GENUS211/bin/genus -file check-startup.tcl
  #cd $(build_dir)/syn-rundir; source ./enter; echo "read_db $(at)" > check-startup.tcl; /ece/cadence/GENUS211/bin/genus -stylus -file check-startup.tcl

.PHONY check-par:
	cd $(build_dir)/par-rundir; source ./enter; /ece/cadence/INNOVUS211/bin/innovus -stylus -db $(at)

.PHONY fix-v-file:
	echo "\`timescale 1ns/1ps" >> $(build_dir)/par-rundir/$(TARGET).sim.v
