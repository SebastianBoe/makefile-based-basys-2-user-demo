PROJECT_NAME = Basys2UserDemo
FPGA_MODEL = xc3s250e-cp132-5
TOP_MODULE = Basys2UserDemo

HDL_FILES = $(wildcard src/*.vhd) $(wildcard src/*.v)

.PHONY: default
default: build/native_generic_database.ngd

# Generate the prj file, which is sort of like
# a list of all the source files that you intend to use.
build/project.prj: $(HDL_FILES)
	{ find src/ -name '*.vhd' -printf "vhdl work %p\n"; \
	  find src/ -name '*.v'   -printf "verilog work %p\n"; } \
	> build/project.prj

# I tried using sed, and even the C preprocessor (big mistake) to
# generate this file. But I have concluded that simply echoing it is
# the best way to do this.
build/xst_script.xst: build/project.prj
	echo "run                           " >  $@
	echo "-ifn build/project.prj" >> $@
	echo "-ofn build/xst_output.ngc" >> $@
	echo "-p $(FPGA_MODEL)              " >> $@
	echo "-top $(TOP_MODULE)            " >> $@
	echo "-opt_level 2                  " >> $@
	echo "-ofmt NGC                     " >> $@
	echo "-keep_hierarchy No            " >> $@
	echo "-work_lib work                " >> $@
	echo >> $@

build/xst_output.ngc: build/xst_script.xst
	xst \
	 -ifn build/xst_script.xst \
	 -ofn build/$(PROJECT_NAME).srp
#	xst creates a bunch of files and the doc doesn't appear to
#	allow a build directory to exist. Since our usage of xst is
#	very simple I think it is fine to just rm the unwanted files
	rm -r $(TOP_MODULE).lso _xmsgs xst

# From the Xilinx Command Line Tools User Guide. Copyrighted Xilinx.
#
# NGDBuild reads in a netlist file in EDIF or NGC format and creates a
# Xilinx® Native Generic Database (NGD) file that contains a logical
# description of the design in terms of logic elements, such as AND
# gates, OR gates, LUTs, flip-flops, and RAMs.
build/native_generic_database.ngd: build/xst_output.ngc src/user_constraints_file.ucf
	ngdbuild \
	$(PROJECT_NAME) \
	-sd build \
	-dd build \
	-quiet \
	-p $(FPGA_MODEL) \
	-uc src/user_constraints_file.ucf \
	-intstyle xflow \
	build/native_generic_database.ngd
	rm -r _xmsgs xlnx_auto_0_xdb

# From the Xilinx Command Line Tools User Guide. Copyrighted Xilinx.

# The MAP program maps a logical design to a Xilinx® FPGA. The input
# to MAP is an NGD file, which is generated using the NGDBuild
# program. The NGD file contains a logical description of the design
# that includes both the hierarchical components used to develop the
# design and the lower level Xilinx primitives. The NGD file also
# contains any number of NMC (macro library) files, each of which
# contains the definition of a physical macro. Finally, depending on
# the options used, MAP places the design.

# MAP first performs a logical DRC (Design Rule Check) on the design
# in the NGD file.  MAP then maps the design logic to the components
# (logic cells, I/O cells, and other components) in the target Xilinx
# FPGA.

# The output from MAP is an NCD (Native Circuit Description) file a
# physical representation of the design mapped to the components in
# the targeted Xilinx FPGA.  The mapped NCD file can then be placed
# and routed using the PAR program.

#Also builds a ncd file
# build/physical_constraints_file.pcf: build/native_generic_database.ngd
# 	map 

clean:
	rm -rf build/*
