# The reader is assumed to either know what each Xilinx program does
# or be willing to read the Xilinx "Command Line Tools User Guide.pdf"
# and the "XST User Guide.pdf"

####################################################################
# Project-dependent variables 
####################################################################
PROJECT_NAME = Basys2UserDemo
FPGA_MODEL = xc3s250e-cp132-5
TOP_MODULE = Basys2UserDemo

# Multithreading the map command. It varies from fpga to fpga if this
# can be enabled. This is a bit ugly, but the map command will not
# accept -mt off so to conditionally support mutlithreading we have to
# conditionally create the command line option "-mt on " or "".  TODO:
# find a more idiomatic way of doing this.
MULTITHREADED_MAP = off 
ifeq ($(MULTITHREADED_MAP), on) 
	MUTLITHREADED_MAP_CMD_LINE_OPTION=-mt on
else
	MUTLITHREADED_MAP_CMD_LINE_OPTION=
endif

#################################################################
# Project independent variables
#################################################################
HDL_FILES = $(wildcard src/*.vhd) $(wildcard src/*.v)

#################################################################
# Makefile body
#################################################################

.PHONY: default
default: build/design.ncd

# Generate the prj file, which is sort of like
# a list of all the source files that you intend to use.
build/project.prj: $(HDL_FILES)
	@{ find src/ -name '*.vhd' -printf "vhdl work %p\n"; \
	  find src/ -name '*.v'   -printf "verilog work %p\n"; } \
	> build/project.prj

# I tried using sed, and even the C preprocessor (big mistake) to
# generate this file. But I have concluded that simply echoing it is
# the best way to do this.
build/xst_script.xst: build/project.prj
	@echo "run                           " >  $@
	@echo "-ifn build/project.prj        " >> $@
	@echo "-ofn build/$(PROJECT_NAME).ngc" >> $@
	@echo "-p $(FPGA_MODEL)              " >> $@
	@echo "-top $(TOP_MODULE)            " >> $@
	@echo "-opt_level 2                  " >> $@
	@echo "-ofmt NGC                     " >> $@
	@echo "-keep_hierarchy No            " >> $@
	@echo "-work_lib work                " >> $@
	@echo >> $@

build/$(PROJECT_NAME).ngc: build/xst_script.xst
	xst \
	 -ifn build/xst_script.xst \
	 -ofn build/$(PROJECT_NAME).srp \
	 -intstyle silent
#	xst creates a bunch of files and the doc doesn't appear to
#	allow a build directory to exist. Since our usage of xst is
#	very simple I think it is fine to just rm the unwanted files
	@rm -r $(TOP_MODULE).lso _xmsgs xst

build/native_generic_database.ngd: build/$(PROJECT_NAME).ngc src/user_constraints_file.ucf
	ngdbuild \
	-p $(FPGA_MODEL) \
	-sd build \
	-dd build \
	-uc src/user_constraints_file.ucf \
	-intstyle silent \
	-quiet \
	$(PROJECT_NAME) \
	build/native_generic_database.ngd > build/ngdbuild.log
	@rm -r _xmsgs xlnx_auto_0_xdb

build/design.ncd: build/native_generic_database.ngd
	map \
	-intstyle silent \
	$(MUTLITHREADED_MAP_CMD_LINE_OPTION) \
	-p $(FPGA_MODEL) \
	-o build/design.ncd \
	build/native_generic_database.ngd \
	build/physical_constraints_file.pcf
	@rm -r \
	xilinx_device_details.xml \
	Basys2UserDemo_map.xrpt \
	_xmsgs/

clean:
	rm -rf build/*
