# Makefile -- Open DFT + LEC flow (Yosys / Icarus / Fault)
# Install: sudo apt install yosys iverilog ; pip install fault
# Docs: https://fault.readthedocs.io

RTL     := rtl/uart_tx.v
TOP     := uart_tx
BUILD   := build
LIB     :=              # optional: path to a liberty file, e.g. sky130
IVERILOG := iverilog
VVP      := vvp

# macOS detection: Homebrew Yosys lacks smt2/smtbmc, use built-in SAT fallback
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
    LEC_SCRIPT := scripts/lec_mac.ys
    LEC_MITER_SCRIPT := scripts/lec_miter_mac.ys
else
    LEC_SCRIPT := scripts/lec.ys
    LEC_MITER_SCRIPT := scripts/lec_miter.ys
endif

equiv-sim: $(BUILD)/uart_tx_synth.v
	sed 's/module uart_tx/module uart_tx_gate/' $(BUILD)/uart_tx_synth.v > $(BUILD)/uart_tx_gate.v
	$(IVERILOG) -g2012 -o $(BUILD)/tb_equiv.vvp rtl/uart_tx.v $(BUILD)/uart_tx_gate.v tb/tb_equiv.v
	$(VVP) $(BUILD)/tb_equiv.vvp | tee $(BUILD)/equiv.log
	grep -q "TESTBENCH PASSED" $(BUILD)/equiv.log

.PHONY: all sim synth lec lec-bug equiv-sim dft sim_occ sim_mbist sim_bsr sim_wrappee sim_tdf clean

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

# 3. Equivalence check (RTL vs gate)
#    Linux: Formal proof via SMT temporal induction (yosys-smtbmc + z3).
#    macOS: Simulation-based lockstep co-sim (Homebrew Yosys lacks smt2/smtbmc).
lec: $(BUILD)/uart_tx_synth.v
ifeq ($(UNAME_S),Darwin)
	@echo "[Mac] Using simulation-based LEC (lockstep co-simulation)"
	$(MAKE) equiv-sim
else
	yosys $(LEC_SCRIPT)
	yosys-smtbmc -i -t 4 -s z3 $(BUILD)/miter.smt2
endif

# 3b. Bug demo: LEC should FAIL with a counterexample
lec-bug: $(RTL) | $(BUILD)
	cp $(BUILD)/uart_tx_synth.v $(BUILD)/uart_tx_synth_golden.v
	yosys -p "read_verilog rtl/uart_tx_buggy.v; synth -top $(TOP) -flatten; write_verilog $(BUILD)/uart_tx_synth.v"
ifeq ($(UNAME_S),Darwin)
	@echo "[Mac] Using simulation-based LEC (expecting FAILURE)"
	sed 's/module uart_tx/module uart_tx_gate/' $(BUILD)/uart_tx_synth.v > $(BUILD)/uart_tx_gate.v
	$(IVERILOG) -g2012 -o $(BUILD)/tb_equiv.vvp rtl/uart_tx.v $(BUILD)/uart_tx_gate.v tb/tb_equiv.v \
	    || true
	$(VVP) $(BUILD)/tb_equiv.vvp | tee $(BUILD)/equiv.log; \
	    if grep -q "TESTBENCH PASSED" $(BUILD)/equiv.log; then \
	        echo "ERROR: Bug was NOT caught"; exit 1; \
	    else \
	        echo "EXPECTED: LEC caught the bug (lockstep mismatch)"; \
	    fi
else
	yosys $(LEC_MITER_SCRIPT)
	yosys-smtbmc -i -t 4 -s z3 $(BUILD)/miter.smt2 || echo "EXPECTED: counterexample found (LEC caught the bug)"
endif
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

# -----------------------------------------------------------------
# Extension targets: OCC, MBIST, BSR (teaching-quality demos)
# -----------------------------------------------------------------

# 5. OCC simulation -- verify 2-pulse generation
sim_occ: $(BUILD)/tb_occ.vvp
	$(VVP) $< | tee $(BUILD)/occ.log
	grep -q "TESTBENCH PASSED" $(BUILD)/occ.log

$(BUILD)/tb_occ.vvp: rtl/occ_simple.v tb/tb_occ.v | $(BUILD)
	$(IVERILOG) -g2012 -o $@ rtl/occ_simple.v tb/tb_occ.v

# 6. MBIST simulation -- March C- on SRAM with fault injection
sim_mbist: $(BUILD)/tb_mbist.vvp
	$(VVP) $< | tee $(BUILD)/mbist.log
	grep -q "TESTBENCH PASSED" $(BUILD)/mbist.log

$(BUILD)/tb_mbist.vvp: rtl/sram_8x16.v rtl/mbist_simple.v tb/tb_mbist.v | $(BUILD)
	$(IVERILOG) -g2012 -o $@ rtl/sram_8x16.v rtl/mbist_simple.v tb/tb_mbist.v

# 7. BSR simulation -- boundary scan register on uart_tx
sim_bsr: $(BUILD)/tb_bsr.vvp
	$(VVP) $< | tee $(BUILD)/bsr.log
	grep -q "TESTBENCH PASSED" $(BUILD)/bsr.log

$(BUILD)/tb_bsr.vvp: rtl/uart_tx.v rtl/uart_tx_bsr.v tb/tb_bsr.v | $(BUILD)
	$(IVERILOG) -g2012 -o $@ rtl/uart_tx.v rtl/uart_tx_bsr.v tb/tb_bsr.v

# 8. Hierarchical DFT -- wrapper INTEST + EXTEST demo
sim_wrappee: $(BUILD)/tb_wrappee.vvp
	$(VVP) $< | tee $(BUILD)/wrappee.log
	grep -q "TESTBENCH PASSED" $(BUILD)/wrappee.log

$(BUILD)/tb_wrappee.vvp: rtl/uart_tx.v rtl/uart_tx_wrapper.v rtl/uart_rx_mini.v rtl/uart_rx_wrapper.v tb/tb_wrappee.v | $(BUILD)
	$(IVERILOG) -g2012 -o $@ rtl/uart_tx.v rtl/uart_tx_wrapper.v rtl/uart_rx_mini.v rtl/uart_rx_wrapper.v tb/tb_wrappee.v

# 9. TDF demo -- 2-pattern at-speed test using scan chain + OCC
sim_tdf: $(BUILD)/tb_tdf.vvp
	$(VVP) $< | tee $(BUILD)/tdf.log
	grep -q "TESTBENCH PASSED" $(BUILD)/tdf.log

$(BUILD)/tb_tdf.vvp: rtl/uart_tx.v rtl/uart_tx_scan.v rtl/occ_simple.v tb/tb_tdf.v | $(BUILD)
	$(IVERILOG) -g2012 -o $@ rtl/uart_tx.v rtl/uart_tx_scan.v rtl/occ_simple.v tb/tb_tdf.v

clean:
	rm -rf $(BUILD) *.vcd
