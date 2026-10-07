# open_dft_lec -- Open-Source DFT + Equivalence-Checking Project

Portfolio project aimed at the **Senior Integration Design Engineer** role
(Silicon Integration Team: fullchip IP integration, DFT, ATPG, equivalence
checking, tapeout-gating audits). Built entirely with open-source EDA tools.

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

    make sim        # self-checking testbench (8'hA5, 8'h3C)
    make synth      # yosys -> build/uart_tx_synth.v (flattened generic netlist)
    make lec        # formal equivalence RTL vs netlist (exit 0 = proven)
    make lec-bug    # demo: LEC catches a deliberate shift-direction bug
    make dft        # Fault toolchain: synth/cut/atpg/compact/chain/tap
    make clean

## What to collect for your resume / interview

1. `make lec` transcript showing `equiv_status` all-proven.
2. `make lec-bug` counterexample from the SAT miter (show it in interviews!).
3. Fault ATPG summary: stuck-at fault coverage %, pattern count, count after
   `fault compact` (compaction ratio).
4. Scan-chain netlist: show SE/SI/SO pins in `uart_tx_scan.v`.
5. JTAG TAP netlist: TDI/TMS/TDO/TCK/TRST pins in `uart_tx_tap.v`.

## Honest limitations

- Open-source ATPG (Fault) targets **stuck-at** faults; transition/at-speed
  and bridging faults are the domain of commercial tools (TetraMAX/ATPG-Fast).
- Fault's pseudo-random ATPG trades pattern optimality for library
  independence; bundled Atalanta/PODEM are free but proprietary for
  commercial use.
- This flow demonstrates the *concepts* the JD asks for (DFT insertion,
  ATPG, equivalence, coverage sign-off) -- be ready to map them to
  Tessent/Conformal terminology.

## Learning resources

- Fault docs: https://fault.readthedocs.io
- WOSET 2019 paper: "Fault, an Open Source DFT Toolchain" (flow theory)
- F-Si talk by Mohamed Gaber (slides + video): wiki.f-si.org -- "Fault,
  Open-Source EDA's Missing DFT Toolchain"
- Yosys LEC: `help equiv_make`, `help sat` inside yosys

## Milestones -> JD mapping

| Milestone | JD bullet |
|---|---|
| make synth + make lec | "Synthesis, Equivalence Check ... industry standard tools" |
| make dft (chain/tap) | "Knowledge in DFT flow" (required skill) |
| make dft (atpg/compact) | "ATPG generation" (required skill) |
| Coverage report write-up | "tapeout-gating audits" |
| RTL + TB quality | "Expertise in Verilog and System Verilog" (expertise sought) |
