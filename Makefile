# Makefile -- Open DFT + LEC flow (Yosys / Icarus / Fault)
# Install: sudo apt install yosys iverilog ; pip install fault
# Docs: https://fault.readthedocs.io

RTL     := rtl/uart_tx.v
TOP     := uart_tx
BUILD   := build
LIB     :=              # optional: path to a liberty file, e.g. sky130
IVERILOG := iverilog
VVP      := vvp

equiv-sim: $(BUILD)/uart_tx_synth.v
	sed 's/module uart_tx/module uart_tx_gate/' $(BUILD)/uart_tx_synth.v > $(BUILD)/uart_tx_gate.v
	$(IVERILOG) -g2012 -o $(BUILD)/tb_equiv.vvp rtl/uart_tx.v $(BUILD)/uart_tx_gate.v tb/tb_equiv.v
	$(VVP) $(BUILD)/tb_equiv.vvp | tee $(BUILD)/equiv.log
	grep -q "TESTBENCH PASSED" $(BUILD)/equiv.log

.PHONY: all sim synth lec lec-bug dft clean

all: sim synth lec

# 1. Golden functional sim (pass/fail via log grep: portable across simulators)
sim: $(BUILD)/uart_tx_tb.vvp
	$(VVP) $< | tee $(BUILD)/sim.log
	grep -q "TESTBENCH PASSED" $(BUILD)/sim.log

$(BUILD)/uart_tx_tb.vvp: $(RTL) tb/uart_tx_tb.v | $(BUILD)
	$(IVERILOG) -g2005 -o $@ $(RTL) tb/uart_tx_tb.v

# 2. Synthesis (generic gates -- fine for LEC + Fault)
synth: $(BUILD)/uart_tx_synth.v

$(BUILD)/uart_tx_synth.v: $(RTL) | $(BUILD)
	yosys -p "read_verilog $(RTL); synth -top $(TOP) -flatten; write_verilog $@" 	  | tee $(BUILD)/synth.log

# 3. Equivalence check (RTL vs gate) via SMT temporal induction.
#    yosys writes build/miter.smt2 (built-in smt2 exporter);
#    yosys-smtbmc driver (separate tool) orchestrates z3.
lec: $(BUILD)/uart_tx_synth.v
	yosys scripts/lec.ys
	yosys-smtbmc -i -t 4 -s z3 $(BUILD)/miter.smt2

# 3b. Bug demo: LEC should FAIL with a counterexample
lec-bug: $(RTL) | $(BUILD)
	yosys -p "read_verilog $(RTL); synth -top $(TOP) -flatten; write_verilog $(BUILD)/uart_tx_synth.v"
	cp $(BUILD)/uart_tx_synth.v $(BUILD)/uart_tx_synth_golden.v
	yosys -p "read_verilog rtl/uart_tx_buggy.v; synth -top $(TOP) -flatten; write_verilog $(BUILD)/uart_tx_synth.v"
	yosys scripts/lec_miter.ys
	yosys-smtbmc -i -t 4 -s z3 $(BUILD)/miter.smt2 || echo "EXPECTED: counterexample found (LEC caught the bug)"
	cp $(BUILD)/uart_tx_synth_golden.v $(BUILD)/uart_tx_synth.v

# 4. DFT flow with fault-dft 0.9.4 (flags matched to this release's --help)
#    Uses the self-contained mini cell library (lib/mini.lib + mini_cells.v)
#    -- no PDK download required. Swap LIB/CELLS for a sky130 liberty +
#    models later if desired (e.g., for the cell_char handshake).
LIB   := lib/mini.lib
CELLS := lib/mini_cells.v
CLOCK := clk
RST   := reset_n

libs: $(LIB) $(CELLS)

# DFT flow: manual synthesis (bypasses ABC segfault on Apple Silicon) + fault pipeline
dft: $(BUILD)/uart_tx_net.v
	fault cut   --output $(BUILD)/uart_tx_cut.v --clock $(CLOCK) --reset $(RST) --reset-active-low $(BUILD)/uart_tx_net.v
	fault atpg  --output $(BUILD)/vectors.json --cell-model $(CELLS) --clock $(CLOCK) \
	            --reset $(RST) --reset-active-low \
	            --output-coverage-metadata $(BUILD)/coverage.yml \
	            $(BUILD)/uart_tx_cut.v
	fault chain --output $(BUILD)/uart_tx_scan.v --liberty $(LIB) --clock $(CLOCK) \
	            --reset $(RST) --reset-active-low --cell-model $(CELLS) $(BUILD)/uart_tx_net.v
	fault tap   --output $(BUILD)/uart_tx_tap.v --liberty $(LIB) --clock $(CLOCK) \
	            --reset $(RST) --reset-active-low --cell-model $(CELLS) $(BUILD)/uart_tx_scan.v
	@echo "== DFT outputs: netlist, cut netlist, vectors.json, coverage.yml, scan chain, JTAG tap =="

# Manual synthesis: yosys with simplemap (no ABC — avoids Apple Silicon crash)
$(BUILD)/uart_tx_net.v: $(RTL) $(LIB) $(CELLS)
	mkdir -p $(BUILD)
	yosys scripts/synth_manual.ys

$(BUILD):
	mkdir -p $(BUILD)

clean:
	rm -rf $(BUILD) *.vcd
