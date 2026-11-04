# DFT Sign-Off Report

| | |
|---|---|
| **Project** | uart_tx — Open DFT + LEC demonstration flow |
| **Design revision** | ⟨git commit hash / tag⟩ |
| **Target role** | Senior Integration Design Engineer — Silicon Integration (DFT/ATPG/LEC focus) |
| **Report owner** | ⟨your name⟩ |
| **Date** | ⟨YYYY-MM-DD⟩ |
| **Sign-off status** | ☐ CONDITIONAL PASS  ☐ FAIL  ☐ WAIVED (justify in §7) |

---

## 1. Executive Summary

One-paragraph summary: block integrated, scan inserted, ATPG completed,
formal equivalence proven, residual risks. Example phrasing:

> The uart_tx block (N logic gates, M flip-flops, 1 scan chain) completed
> the full DFT flow. Stuck-at fault coverage of ⟨XX.X⟩% was achieved with
> ⟨N⟩ compacted patterns. Formal LEC between RTL and the scan-inserted
> netlist passed with zero non-equivalent points.

## 2. Design Under Test

| Item | Value |
|---|---|
| Block name | uart_tx |
| Function | 8N1 UART transmitter (FSM + 10-bit shift register) |
| Flip-flops (pre-scan) | ⟨N⟩ (yosys `stat`) |
| Flip-flops (post-scan) | ⟨N⟩ — delta must be 0 (scan muxing reuses existing FFs) |
| Logic gates | ⟨N⟩ |
| Clock domains | 1 |
| Reset | Async active-low (`reset_n`) |
| Primary inputs | clk, reset_n, data[7:0], send |
| Primary outputs | tx, busy, done |

## 3. Tool & Flow Versions

| Step | Tool | Version / source |
|---|---|---|
| Simulation | Icarus Verilog | ⟨iverilog -V⟩ |
| Synthesis + LEC | Yosys | ⟨yosys -V⟩ |
| Scan/ATPG/compaction/JTAG | Fault (AUCOHL) | ⟨pip show fault⟩ |
| Cell library | ⟨generic / sky130 ...⟩ | ⟨liberty file name⟩ |

Flow: `make sim → make synth → make lec → make dft`

## 4. Functional Verification Sign-Off

| Check | Result | Evidence |
|---|---|---|
| RTL testbench | ☐ PASS | `build/sim.log` — 2 frames checked (0xA5, 0x3C) |
| Golden vectors archived | ☐ YES | `tb/uart_tx_tb.v` |

## 5. Formal Equivalence (LEC) Sign-Off

| Check | Tool | Result |
|---|---|---|
| RTL vs synthesized netlist (functional mode) | Yosys `equiv_make/equiv_simple/equiv_status` | ☐ PASS — ⟨N/N⟩ points proven |
| RTL vs **scan-inserted** netlist (scan_enable tied 0) | Yosys equiv | ☐ PASS — ⟨N/N⟩ |
| Bug-injection negative test (SAT miter counterexample) | Yosys `sat -verify` | ☐ CAUGHT — see `make lec-bug` log |

Notes for review:
- Equivalence of the scan netlist is proven with `scan_en = 0` (functional
  mode); shift-mode timing is verified structurally (§6), not by LEC — this
  matches industry practice for mux-D scan.
- Attach transcript: `build/lec_transcript.log`

## 6. Scan & Test Access Sign-Off

| Check | Result | Evidence |
|---|---|---|
| Scan chain count / length | ⟨1⟩ chain(s), ⟨M⟩ FFs | `build/uart_tx_scan.v` |
| Scan ports present (SE, SI, SO, scan_clk) | ☐ YES | netlist inspection |
| Scan-chain integrity (shift test: SI → SO toggles observed in sim) | ☐ PASS | ⟨sim log ref⟩ |
| No logic between scan FFs (chain stitch check) | ☐ PASS | netlist inspection |
| JTAG TAP (1149.1-style) inserted: TDI/TMS/TDO/TCK/TRST | ☐ YES | `build/uart_tx_tap.v` |
| TAP `ScanIn` instruction reaches chain | ☐ PASS | ⟨sim log ref⟩ |
| Reset behavior: TAP in Test-Logic-Reset after reset_n | ☐ PASS | ⟨sim log ref⟩ |

DFT overhead:

| Metric | Pre-scan | Post-scan | Delta |
|---|---|---|---|
| Gate count | ⟨N⟩ | ⟨N⟩ | ⟨N⟩ |
| FF count | ⟨N⟩ | ⟨N⟩ | 0 expected |

## 7. ATPG Sign-Off (Stuck-At)

| Metric | Value |
|---|---|
| Fault model | Stuck-at-0 / stuck-at-1, collapsed |
| Total faults | ⟨N⟩ |
| Detected | ⟨N⟩ |
| Coverage | **⟨XX.X⟩ %** |
| Patterns (raw, `fault atpg`) | ⟨N⟩ |
| Patterns (compacted, `fault compact`) | ⟨N⟩ |
| Compaction ratio | ⟨X.X⟩× |
| ATPG engine | ⟨Fault pseudo-random / Atalanta PODEM⟩ |

Residual / undetected faults:

| Fault | Location (if known) | Reason | Disposition |
|---|---|---|---|
| ⟨e.g. stuck-at on tx pad keeper⟩ | ⟨...⟩ | ⟨untestable / no access⟩ | ⟨waived: redundant / will add test point⟩ |

Honest limitations (state these in the interview):
- Coverage ceiling is a function of the open-source engine (pseudo-random
  + optional PODEM); commercial ATPG with compaction + dynamic DFT would
  trade differently.
- Transition/at-speed (launch-off-shift/capture) and bridging faults are
  **out of scope** for this open-source flow.

## 8. Risks & Recommendations

1. ⟨e.g. single clock domain assumed — no OCC needed; flag if design grows⟩
2. ⟨e.g. coverage on reset synchronizer logic — recommend reset bypass during test⟩
3. ⟨recommend test points if coverage < 99% in real silicon⟩

## 9. Sign-Off Statement

All DFT insertion, ATPG, and equivalence checks for block `uart_tx` at
revision ⟨hash⟩ are complete per §4–§7. Exceptions are listed in §7 and
§8. **Signed:** ⟨name / date⟩

---

## Appendix A — JD mapping (Senior Integration Design Engineer, Lattice)

| JD requirement | This report |
|---|---|
| "Knowledge in DFT flow" (required) | §6 scan insertion + JTAG TAP |
| "ATPG generation" (required) | §7 coverage & pattern report |
| "Equivalence Check ... industry standard tools" | §5 LEC results + negative test |
| "tapeout-gating audits" | This document, in total |
| "verification is a plus" (Perl/TCL/Shell/Python) | The Makefile + Yosys/Fault scripts are automatable — mention `make dft` |
| "RTL coding and verification" | §4 + RTL/TB in repo |

## Appendix B — Reproduce

```bash
git clone ⟨repo⟩ && cd ⟨repo⟩
make sim && make synth && make lec && make lec-bug && make dft
```
