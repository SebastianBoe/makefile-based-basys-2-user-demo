Project structure

src 
Contains all non-generated files except for the Makefile itself. This
includes HDL code, and some synthesis input files to Xilinx.

build
Contains all generated files that are not considered important enough
to go in bin.

bin
Contains important synthesis results, like the final bit file. I
haven't quite decided upon the partitioning of build and bin.
