BOARD=tangnano1k
FAMILY=GW1NZ-1
DEVICE=GW1NR-LV1QN48C6/I5

all: HBC_Interface1.fs

# Synthesis
HBC_Interface1.json: HBC_Interface1.v
	yosys -p "read_verilog HBC_Interface1.v; synth_gowin -top HBC_Interface1 -json HBC_Interface1.json"

# Place and Route
HBC_Interface1_pnr.json: HBC_Interface1.json
	nextpnr-gowin --json HBC_Interface1.json --freq 27 --write HBC_Interface1_pnr.json --device ${DEVICE} --family ${FAMILY} --cst ${BOARD}.cst

# Generate Bitstream
HBC_Interface1.fs: HBC_Interface1_pnr.json
	gowin_pack -d ${FAMILY} -o HBC_Interface1.fs HBC_Interface1_pnr.json

# Program Board
load: HBC_Interface1.fs
	openFPGALoader -b ${BOARD} HBC_Interface1.fs -f

HBC_Interface1_test.o: HBC_Interface1.v HBC_Interface1_tb.v
	iverilog -o HBC_Interface1_test.o -s test HBC_Interface1.v HBC_Interface1_tb.v

test: HBC_Interface1_test.o
	vvp HBC_Interface1_test.o

# Cleanup build artifacts
clean:
	rm HBC_Interface1.vcd HBC_Interface1.fs HBC_Interface1_test.o

.PHONY: load clean test
.INTERMEDIATE: HBC_Interface1_pnr.json HBC_Interface1.json HBC_Interface1_test.o