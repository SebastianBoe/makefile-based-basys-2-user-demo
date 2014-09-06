PROJECT_NAME = Basys2UserDemo
FPGA_MODEL = xc3s250e-cp132-5
TOP_MODULE = Basys2UserDemo

HDL_FILES = $(wildcard src/*.vhd) $(wildcard src/*.v)

.PHONY: default
default: build/$(PROJECT_NAME).ngd

# TODO: have the Makefile create the build dir. 
# Generate the prj file, which is sort of like
# a list of all the source files that you intend to use.
build/$(PROJECT_NAME).prj: $(HDL_SOURCE_FILES)
	{ find src/ -name '*.vhd' -printf "vhdl work %p\n"; \
	  find src/ -name '*.v'   -printf "verilog work %p\n"; } \
	> build/$(PROJECT_NAME).prj

# I tried using sed, and even the C preprocessor (big mistake) to
# generate this file. But I have concluded that simply echoing it is
# the best way to do this.
build/$(PROJECT_NAME).xst: build/$(PROJECT_NAME).prj
	echo "run                           " >  $@
	echo "-ifn build/$(PROJECT_NAME).prj" >> $@
	echo "-ofn build/$(PROJECT_NAME).ngc" >> $@
	echo "-p $(FPGA_MODEL)              " >> $@
	echo "-top $(TOP_MODULE)            " >> $@
	echo "-opt_level 2                  " >> $@
	echo "-ofmt NGC                     " >> $@
	echo "-keep_hierarchy No            " >> $@
	echo "-work_lib work                " >> $@
	echo >> $@

build/$(PROJECT_NAME).ngc: build/$(PROJECT_NAME).xst
	xst \
	 -ifn build/$(PROJECT_NAME).xst\
	 -ofn build/$(PROJECT_NAME).syr
#	rm $(TOP_MODULE).lso # I don't get why this file needs to exist.

build/$(PROJECT_NAME).ngd: build/$(PROJECT_NAME).ngc
	ngdbuild \
	$(PROJECT_NAME) \
	-sd build \
	-dd build \
	-p $(FPGA_MODEL) \
	-uc src/$(PROJECT_NAME).ucf \
	-intstyle xflow

clean:
	rm -rf build/* xst _xmsgs $(TOP_MODULE).lso
