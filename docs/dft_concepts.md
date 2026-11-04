# DFT Concepts Covered — 16-Week Self-Study Curriculum

This document maps the DFT concepts studied alongside the `open_dft_lec` hands-on project.
Each week connects theory to a specific part of the open-source flow or a conceptual extension.

---

## Week 1 — DFT Fundamentals

| Topic | Key Concept | Project Connection |
|-------|-------------|-------------------|
| Why test? | Manufacturing defects, process variation, cost of escape | Foundation for all DFT decisions |
| Defect vs. Fault vs. Error | Physical → Logical → Observable | Understanding fault model abstraction |
| Fault models | Stuck-at-0, stuck-at-1, transition, bridging | `fault atpg` targets stuck-at faults |
| Controllability / Observability | Why sequential ATPG is hard | Motivation for scan insertion (`fault cut`) |
| Test plans | What to test, how to test, when to test | `DFT_SIGNOFF_REPORT.md` structure |

**Interview point:** *"DFT exists because sequential circuits have low controllability and observability. Scan chains turn FFs into shift registers, making ATPG linear instead of exponential."*

---

## Week 2 — Scan Insertion

| Topic | Key Concept | Project Connection |
|-------|-------------|-------------------|
| Scan flip-flop | Muxed DFF with SI/SE/SO ports | `fault cut` replaces `$_DFF_P_` with scan cells |
| Scan operation | Shift mode (SE=1) vs. Capture mode (SE=0) | `uart_tx_scan.v` has SE/SI/SO pins |
| Scan types | Full scan, partial scan, boundary scan | This project uses **full scan** |
| Clock/Reset DRCs | All clocks controllable, reset reachable | Single clock `clk`, async `rst_n` — clean |
| Top-down vs. Bottom-up | When to insert scan at RTL vs. netlist | `fault cut` runs on synthesized netlist |

**Interview point:** *"My project uses full scan — all 10 FFs became scan cells. The SE pin selects between functional data and the serial shift path."*

---

## Week 3 — Scan Chain Architecture

| Topic | Key Concept | Project Connection |
|-------|-------------|-------------------|
| Chain stitching | SO[i] → SI[i+1] serial connection | `fault chain` generates `uart_tx_scan.v` |
| Lock-up latches | Between opposite-edge or cross-domain FFs | Not needed — all FFs are posedge, one clock |
| Terminal lock-up | Isolate last FF from pad capacitance | Single chain, no pad — not applicable |
| Edge/domain mixing | One chain = one clock + one edge | `uart_tx` is single-domain |
| Chain balancing | Equal length for parallel chains | Single chain = trivially balanced |

**Interview point:** *"Industrial designs use 100s of parallel chains. My teaching project uses one chain to demonstrate the concept without the complexity of balancing and reordering."*

---

## Week 4 — Compression (EDT)

| Topic | Key Concept | Project Connection |
|-------|-------------|-------------------|
| Static compaction | Remove redundant patterns after ATPG | `fault compact` reduces pattern count |
| Dynamic compaction | Target multiple faults per pattern | `fault atpg` does this to some degree |
| Structural compression | LFSR seed → expanded scan load | **Conceptual** — not in open-source Fault |
| Decompressor/Compactor | On-chip logic for pattern reduction | **Conceptual** — Tessent/DFTMAX feature |
| Masking logic | Block X states from corrupting signature | **Conceptual** — required for designs with X sources |

**Interview point:** *"My project demonstrates static compaction with Fault. I also understand industrial EDT: LFSR seeds expand into full scan loads, and compactors/XOR trees reduce data volume 50-250x."*

---

## Week 5 — ATPG Fault Models & Algorithms

| Topic | Key Concept | Project Connection |
|-------|-------------|-------------------|
| D-algorithm | {0, 1, X, D, D̄} algebra for fault detection | How `fault atpg` finds patterns internally |
| PODEM / FAN | Path-oriented and fanout-oriented ATPG | Alternative algorithms used in commercial tools |
| Fault collapsing | Equivalent faults detected by same pattern | Reduces fault list before ATPG |
| Fault simulation | Verify detection by simulating good + faulty machine | Fault does this internally |
| Pseudo-random ATPG | Random patterns + deterministic fill | Fault's default mode |

**Interview point:** *"ATPG is fundamentally SAT-solving: find an input vector that produces different outputs between the good machine and the faulty machine. The D-algorithm uses D/D̄ notation to track fault propagation."*

---

## Week 6 — ATPG DRCs & Coverage Analysis

| Topic | Key Concept | Project Connection |
|-------|-------------|-------------------|
| DRC categories | Clock/reset, scan chain, bus, cell-level | `DFT_SIGNOFF_REPORT.md` §6 lists manual checks |
| Fault classes | DS, DI, PU, UU, TI, BL, NC, NO | Understand what each means in a coverage report |
| Coverage formula | (DS+DI) / (Total - Untestable) | Target >99% for production |
| Debug NC/NO | Add control points or observe points | **Conceptual** — would use `add_test_point` in commercial tools |
| Test points | Control point (force value) vs. observe point (tap signal) | Fix for ATPG-limited faults |

**Interview point:** *"I know how to read a fault coverage report. DS/DI are good. NC means the fault site can't be controlled — fix with a control point. NO means the fault effect can't be observed — fix with an observe point."*

---

## Week 7 — Transition Delay Faults (TDF) & STA

| Topic | Key Concept | Project Connection |
|-------|-------------|-------------------|
| Why TDF? | Resistive opens, weak drivers, process variation | Stuck-at misses delay defects |
| STR / STF | Slow-to-rise, slow-to-fall | Every node has 2 TDF faults |
| Two-pattern ATPG | Initialization + Launch + Capture | Required for transition testing |
| LOC (Launch-on-Capture) | Functional clock launches transition | Simpler hardware, lower coverage |
| LOS (Launch-on-Shift) | Last shift clock is launch | Higher coverage, needs SE timing |
| STA connection | TDF validates what STA predicts | Critical paths = PDF targets |

**Interview point:** *"Stuck-at tests DC functionality. TDF tests speed — a resistive open might pass stuck-at but fail at rated clock speed. My project is stuck-at only, but I understand the concepts of two-pattern ATPG, LOC/LOS, and the need for at-speed clocking."*

---

## Week 8 — Pattern Types, Formats & OCC

| Topic | Key Concept | Project Connection |
|-------|-------------|-------------------|
| Pattern types | Broadside (LOC), Skewed-load (LOS), Hybrid | Industrial tools generate both |
| STIL format | Standard Test Interface Language (IEEE 1450) | Industrial tester format; project uses JSON |
| WGL / SVF | Alternative pattern formats | Tessent/Synopsys outputs |
| Fault grading | Verify ATPG claims with simulation | Catches optimistic implications |
| OCC (On-Chip Clock) | Generate at-speed pulses using PLL | **Conceptual** — can add `rtl/occ_simple.v` |
| Clock muxing | Glitch-free switch between slow and fast | Required for clean launch/capture |

**Interview point:** *"I understand that testers can't deliver clean fast clocks through cables, so the chip generates its own at-speed pulses using the PLL. The OCC FSM produces exactly 2 pulses — launch and capture — then returns to slow shift mode."*

---

## Week 9 — Simulation Mismatch Debug

| Topic | Key Concept | Project Connection |
|-------|-------------|-------------------|
| Mismatch types | ATPG optimism, X propagation, chain integrity, library mismatch | `make equiv-sim` validates gate netlist |
| Lockstep co-simulation | Run RTL and gate with identical stimulus, compare outputs | `tb/tb_equiv.v` — 5000 cycles |
| X propagation | Unknown states corrupt comparisons | Check initialization in testbench |
| Scan integrity test | Walking 1/0 through chain | Manual inspection in project |
| Zero-delay vs. SDF | Different timing models find different bugs | Project uses zero-delay; SDF is extension |

**Interview point:** *"I validate my DFT netlist with lockstep co-simulation — RTL and gate netlist run side-by-side with randomized stimulus. Any mismatch flags a synthesis or scan insertion error immediately."*

---

## Week 10 — JTAG / IJTAG

| Topic | Key Concept | Project Connection |
|-------|-------------|-------------------|
| IEEE 1149.1 | TAP FSM, 5 pins (TCK/TMS/TDI/TDO/TRST) | `fault tap` generates `uart_tx_tap.v` |
| TAP FSM | 16 states, TMS controls transitions | 5 TMS highs = reset from any state |
| Instructions | EXTEST, BYPASS, SAMPLE, IDCODE, INTEST | SCAN is custom for internal chain access |
| Boundary scan | Shift register at every I/O pin | Tests PCB traces without physical probes |
| IEEE 1687 (IJTAG) | Reconfigurable scan networks, SIBs | **Conceptual** — ICL/PDL for SoC-scale DFT |

**Interview point:** *"My project wraps the internal scan chain in a JTAG TAP with a custom SCAN instruction. The TAP FSM is controlled by TMS — five consecutive highs always returns to Test-Logic-Reset, regardless of current state."*

---

## Week 11 — MBIST & Memory Test Algorithms

| Topic | Key Concept | Project Connection |
|-------|-------------|-------------------|
| Memory fault models | SA0/SA1, coupling, disturb, retention | Unique to dense array structures |
| March algorithms | Regular sequences of w/r operations | March C- = industry standard (10N) |
| MATS+ | Fast 5N algorithm, basic coverage | Good for quick screening |
| MBIST controller | Hardware block running March tests autonomously | **Conceptual extension** — can add SRAM+MBIST |
| MISR | Compacts millions of pass/fail into signature | Reduces tester data to single value |

**Interview point:** *"Memories need specialized test because they have analog-like failure modes — coupling, disturb, retention — that logic ATPG doesn't catch. March C- is the industry standard: 10 operations per cell, covering stuck-at, transition, and coupling faults."*

---

## Week 12 — Hierarchical DFT & Scan Wrappers

| Topic | Key Concept | Project Connection |
|-------|-------------|-------------------|
| Why hierarchical? | Flat ATPG doesn't scale to billion-gate SoCs | Divide and conquer: core-level + top-level |
| Scan wrapper | Shell around core with scan cells on all I/Os | Enables INTEST/EXTEST/BYPASS |
| INTEST | Test core internal logic through wrapper | Core-level ATPG patterns |
| EXTEST | Test interconnect between cores | Top-level ATPG for wiring |
| IEEE 1500 | Wrapper standard: WSI/WSO/WRCK/WIR | JTAG-for-cores |

**Interview point:** *"Modern SoCs use hierarchical DFT. Each core gets a scan wrapper with IEEE 1500 ports. INTEST runs the core's own ATPG patterns. EXTEST tests the wiring between cores. The integrator doesn't need to see inside a gray-box IP."*

---

## Week 13 — EDT Hierarchy, ICL/PDL & Advanced Topics

| Topic | Key Concept | Project Connection |
|-------|-------------|-------------------|
| Hierarchical EDT | Each core has decompressor/compactor | Top-level coordinates seeds/signatures |
| EDT modes | Broadcast, independent, serial, staggered | Staggered launch avoids SSN/power droop |
| Global OCC | Coordinates at-speed launch across cores | One controller, multiple PLL domains |
| Clock monitoring | Verify PLL frequency before test | Ensures valid at-speed test |
| ICL | Instrument Connectivity Language (IEEE 1687) | Describes scan network topology |
| PDL | Procedure Description Language | Portable tests retargeted to each chip variant |
| Fault merging | Combine hierarchical lists without double-counting | Total coverage = merged core + top |

**Interview point:** *"IJTAG uses Segment Insertion Bits (SIBs) to dynamically configure the scan path. ICL describes the network topology. PDL describes test procedures abstractly — the retargeter converts them to actual TDI/TDO sequences for each chip variant."*

---

## Week 14-15 — BISR & Final Review

| Topic | Key Concept | Project Connection |
|-------|-------------|-------------------|
| Why BISR? | Repair defective memories, improve yield | Without BISR, one bad bit = scrap |
| Redundancy | Spare rows, spare columns | Replace defective with spare |
| Repair algorithms | Mustache, greedy | Minimize spare usage |
| Fuse types | Laser, eFuse, antifuse | eFuse most common in modern SoCs |
| Yield impact | 70% → 95% with BISR | Economics of advanced nodes |
| Auxiliary pins | TEST_EN, BISR_EN, FUSE_PROG | Manufacturing-only pins |

**Interview point:** *"At 5nm, a die costs hundreds of dollars. BISR with spare rows and columns can recover 25% of dies that would otherwise be scrapped. eFuses store the repair map permanently; it's read at every boot to configure redundancy registers."*

---

## Honest Project Scope

| What's Implemented | What's Conceptual |
|-------------------|-------------------|
| ✅ Synthesis (Yosys) | ❌ TDF/LOS/OCC hardware |
| ✅ Formal LEC (Yosys + z3) | ❌ SDF-annotated simulation |
| ✅ Lockstep co-simulation | ❌ EDT/LFSR compression hardware |
| ✅ Stuck-at ATPG (Fault) | ❌ Hierarchical wrappers (1500) |
| ✅ Static compaction | ❌ IJTAG network (1687) |
| ✅ Scan chain stitching | ❌ MBIST controller |
| ✅ JTAG TAP (1149.1) | ❌ BISR / fuse programming |
| ✅ Self-contained standard cell library | ❌ Gray-box IP integration |

**This is intentional.** The project demonstrates **hands-on skill** with the complete open-source flow, while the conceptual study shows **breadth** across the full industrial DFT landscape. Both are needed for DFT, digital design, or silicon validation interviews.

---

## Learning Resources

| Resource | Type | Best For |
|----------|------|----------|
| [Fault docs](https://fault.readthedocs.io) | Documentation | Tool commands and flow |
| [TechnoByte DFT](https://technobyte.org/design-for-testability-course-vlsi-dft/) | Articles | Conceptual depth, better than any free video |
| [NPTEL IIT Madras](https://www.youtube.com/watch?v=1OoJG8CeFns) | Video (51 min) | Academic foundation |
| [Maven Silicon Free DFT](https://elearn.maven-silicon.com/course/DesignforTestability-50) | Free course | 4.7/5, full flow with labs |
| [WOSET 2019 Paper](https://woset-workshop.github.io/PDFs/2019/a13.pdf) | PDF | Fault architecture and design decisions |
| This project (`open_dft_lec`) | Hands-on | End-to-end flow you can run and modify |
