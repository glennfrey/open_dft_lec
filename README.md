# open_dft_lec -- Open-Source DFT + Equivalence-Checking Project

End-to-end open-source DFT portfolio demonstrating scan insertion, ATPG,
equivalence checking, and test infrastructure design — built entirely with
free EDA tools (Icarus, Yosys, Fault). Covers stuck-at ATPG, BIST, boundary
scan, hierarchical wrappers, and at-speed test concepts.

**Skills demonstrated:** Digital design (Verilog), synthesis, formal
verification, DFT architecture, test pattern generation, and pre-silicon
validation.

## Toolchain

| Task | Tool | Install |
|---|---|---|
| Simulation | Icarus Verilog | `sudo apt install iverilog` |
| Synthesis + LEC | Yosys (+ABC, SAT) | `sudo apt install yosys` |
| Scan insertion, ATPG, compaction, JTAG | Fault (AUCOHL) | `pip install fault` |
| Docs | fault.readthedocs.io | online |

## Design under test: `uart_tx`

Minimal 8N1 UART transmitter (FSM + 10-bit shift register, 10 flip-flops).
Small enough for fast ATPG, real enough to demonstrate scan + stuck-at
fault grading on a sequential design.

## Flow

```
rtl/uart_tx.v --+--> iverilog (golden TB) --> PASS
                |
                +--> yosys synth -flatten --> build/uart_tx_synth.v
                |        |
                |        +--> yosys equiv_make/equiv_simple/equiv_status (LEC)
                |        |
                +--> fault synth --> cut --> atpg --> compact --> chain --> tap
                                                   |        |        |       |
                                              vectors.json  compacted  scan   JTAG
                                                                .json    netlist  TAP netlist
```

## Commands

    make sim          # self-checking testbench (8'hA5, 8'h3C)
    make synth        # yosys -> build/uart_tx_synth.v (flattened generic netlist)
    make lec          # formal equivalence RTL vs netlist (exit 0 = proven)
    make lec-bug      # demo: LEC catches a deliberate shift-direction bug
    make dft          # Fault toolchain: synth/cut/atpg/compact/chain/tap
    make sim_occ      # OCC: 2-pulse at-speed clock generator
    make sim_mbist    # MBIST: March C- on SRAM with fault injection
    make sim_bsr      # BSR: boundary scan register (SAMPLE/EXTEST)
    make sim_wrappee  # Hierarchical DFT: wrapper INTEST + EXTEST
    make sim_tdf      # TDF: 2-pattern at-speed test (manual demo)
    make clean

## To Do

1. `make lec` transcript showing equivalence proven — demonstrates formal (Linux)
   or simulation-based lockstep (macOS) verification methodology.
2. `make lec-bug` counterexample from the SAT miter (Linux) or lockstep mismatch
   (macOS) — great for explaining how LEC catches RTL vs. gate mismatches.
3. Fault ATPG summary: stuck-at fault coverage %, pattern count, count after
   `fault compact` (compaction ratio) — shows understanding of test economics.
4. Scan-chain netlist (`uart_tx_scan.v`) — explain SE/SI/SO pin additions and
   how scan enables controllability/observability.
5. JTAG TAP netlist (`uart_tx_tap.v`) — walk through the 16-state FSM, IR/DR
   registers, and BYPASS/IDCODE instructions.
6. BIST + wrapper demos — explain MBIST March C- flow or INTEST/EXTEST
   wrapper operation for hierarchical test.

## Honest limitations

- Open-source ATPG (Fault) targets **stuck-at** faults; transition/at-speed
  and bridging faults are the domain of commercial tools (TetraMAX/ATPG-Fast).
- Fault's pseudo-random ATPG trades pattern optimality for library
  independence; bundled Atalanta/PODEM are free but proprietary for
  commercial use.
- This flow demonstrates the *concepts* used in industry (DFT insertion,
  ATPG, equivalence checking, coverage sign-off) — be ready to map them to
  Tessent/Conformal or Modus/Encounter Test terminology.

## Learning resources

- Fault docs: https://fault.readthedocs.io
- WOSET 2019 paper: "Fault, an Open Source DFT Toolchain" (flow theory)
- F-Si talk by Mohamed Gaber (slides + video): wiki.f-si.org -- "Fault,
  Open-Source EDA's Missing DFT Toolchain"
- Yosys LEC: `help equiv_make`, `help sat` inside yosys
- Full 16-week DFT curriculum: [`docs/dft_concepts.md`](docs/dft_concepts.md)

## 16-Week DFT Curriculum (Self-Study)

This project is paired with a structured 16-week DFT curriculum covering the
full industrial flow from scan basics to hierarchical DFT and BISR.

| Week | Topic | Hands-On / Conceptual |
|------|-------|----------------------|
| 1 | DFT Basics — Defect/Fault/Error, Test Plans | Conceptual |
| 2 | Scan Insertion — Types, Clock/Reset DRCs | `fault cut` |
| 3 | Scan Chain Architecture — Lock-up, Balancing | `fault chain` |
| 4 | Compression — LFSR, Decompressor, Compactor | `fault compact` |
| 5 | ATPG Fault Models — D-algorithm, PODEM, FAN | `fault atpg` |
| 6 | ATPG DRCs, Coverage, Fault Classes | Inspect `vectors.json` |
| 7 | TDF / PDF / STA Basics — At-speed testing | `make sim_tdf` (manual 2-pattern) |
| 8 | Pattern Types (LOC/LOS), STIL, OCC | `make sim_occ` |
| 9 | Simulation Mismatch Debug — Lockstep co-sim | `make equiv-sim` |
| 10 | JTAG / IJTAG — TAP FSM, Boundary Scan | `fault tap` + `make sim_bsr` |
| 11 | MBIST — March Algorithms, Memory Faults | `make sim_mbist` |
| 12 | Hierarchical DFT — Scan Wrappers, 1500 | `make sim_wrappee` |
| 13 | EDT Hierarchy, ICL/PDL, Staggered Launch | Conceptual |
| 14-15 | BISR — Spare Rows/Columns, Fuse Programming | Conceptual |
| 16 | Interview Prep — Mock questions, project presentation | — |

**What is implemented vs. conceptual:**
- **Implemented (can run):** Synthesis, LEC, lockstep co-simulation, stuck-at ATPG,
  static compaction, scan chain stitching, JTAG TAP, **OCC 2-pulse generator**,
  **MBIST controller (March C-)**, **boundary scan register (BSR)**,
  **hierarchical scan wrappers (INTEST/EXTEST)**, **manual 2-pattern TDF sequence**
- **Conceptual (studied, not built):** EDT/LFSR compression hardware at scale,
  full IJTAG networks (IEEE 1687), BISR fuse programming, commercial tool flows

See [`docs/dft_concepts.md`](docs/dft_concepts.md) for the full week-by-week breakdown with
interview talking points for each topic.

## Skills Demonstrated

| Milestone | Skill |
|---|---|
| `make synth` + `make lec` | Synthesis, formal equivalence checking, netlist quality assurance |
| `make dft` (chain / tap) | Scan insertion, JTAG TAP design, test infrastructure architecture |
| `make dft` (atpg / compact) | ATPG algorithm understanding, pattern compaction, fault grading |
| `make sim_mbist` | Memory BIST controller design, March algorithm implementation |
| `make sim_bsr` + `make sim_wrappee` | Boundary scan (IEEE 1149.1), hierarchical wrappers (IEEE 1500) |
| `make sim_tdf` + `make sim_occ` | At-speed test concepts, launch-off-capture / launch-off-shift |
| RTL + TB quality | Verilog design, self-checking testbench architecture, coverage-driven validation |
