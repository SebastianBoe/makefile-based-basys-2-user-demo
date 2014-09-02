PROJECT_NAME = Basys2UserDemo
FPGA_MODEL = xc3s250e-cp132-5
TOP_MODULE = Basys2UserDemo
VHDL_SOURCE_FILES = $(wildcard src/*.vhd)

build/proj.ngc: build/xst_commands.xst
	xst \
	 -ifn build/xst_commands.xst\
	 -ofn build/$(PROJECT_NAME).syr

# I tried using sed, and even the C preprocessor to generate this
# file. But I have concluded that simply echoing it is the best way to
# do this.
build/xst_commands.xst: build/source_files.prj
	echo "run                         " >  $@
	echo "-ifn build/source_files.prj " >> $@
	echo "-ofn build/proj.ngc         " >> $@
	echo "-p $(FPGA_MODEL)            " >> $@
	echo "-top $(TOP_MODULE)          " >> $@
	echo "-opt_level 2                " >> $@
	echo "-ofmt NGC                   " >> $@
	echo "-keep_hierarchy No          " >> $@
	echo "-work_lib work              " >> $@
	echo >> $@

#todo require build dir.
build/source_files.prj: $(VHDL_SOURCE_FILES)
	{ find src/ -name '*.vhd' -printf "vhdl work %p\n"; \
	  find src/ -name '*.v'   -printf "verilog work %p\n"; } \
	> build/source_files.prj

clean:
	rm -rf build/* xst _xmsgs
