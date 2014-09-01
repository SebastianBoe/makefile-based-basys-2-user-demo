PROJECT_NAME = Basys2UserDemo

VHDL_SOURCE_FILES = $(wildcard src/*.vhd)

syntax: $(VHDL_SOURCE_FILES) build/source_files.prj
	xst -ifn xst_commands.xst -ofn build/xst_log -intstyle xflow

#todo require build dir.
build/source_files.prj: $(VHDL_SOURCE_FILES)
	{ find src/ -name '*.vhd' -printf "vhdl work %p\n"; \
	  find src/ -name '*.v'   -printf "verilog work %p\n"; } > build/source_files.prj
