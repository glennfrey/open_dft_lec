# LinkedIn Post Drafts for open_dft_lec

**Image to use:** `docs/linkedin_pipeline_final.png` — the pipeline flow diagram.
Upload this as the post image. LinkedIn crops to 1200×627 (landscape); this is 16:9 and will display cleanly.

Pick the version that matches your style, or mix and match.

---

## Version 1: Technical & Direct (Recommended)

I built a complete open-source DFT pipeline from scratch — synthesis, formal equivalence checking, scan insertion, ATPG, pattern compaction, JTAG TAP, MBIST, boundary scan, and hierarchical test wrappers.

All running with free tools: Icarus Verilog, Yosys, and Fault (AUCOHL).

What it covers:

- Synthesis → formal LEC (RTL vs gate proven equivalent)
- Scan chain insertion with SE/SI/SO pins
- Stuck-at ATPG with fault grading and compaction
- JTAG TAP controller (16-state FSM, IR/DR, BYPASS/IDCODE)
- Memory BIST with March C- algorithm and fault injection
- Boundary scan register (SAMPLE / EXTEST modes)
- IEEE 1500 hierarchical wrappers (INTEST / EXTEST)
- At-speed test demo with OCC 2-pulse generator

Every module has a self-checking testbench. Every target is one `make` command away.

GitHub: github.com/glennfrey/open_dft_lec

Also wrote a 16-week self-study curriculum mapping each topic to hands-on commands and interview talking points.

If you're learning DFT or hiring for it — take a look.

#DFT #ATPG #VLSI #Semiconductor #OpenSourceEDA #DigitalDesign #FormalVerification #ScanTest #JTAG #MBIST #Yosys #Verilog

---

## Version 2: Story / Journey

Sixteen weeks ago I started self-studying Design-for-Test with the goal of understanding how silicon gets tested before it ever sees a wafer probe.

Today I'm sharing the result: a complete open-source DFT portfolio built from the ground up.

The project takes a minimal UART transmitter through the full industrial flow:

- Yosys synthesis and formal equivalence checking
- Scan insertion and stuck-at ATPG with the Fault toolchain
- Pattern compaction and fault grading
- JTAG TAP controller with full 16-state FSM
- Memory BIST (March C-) with stuck-at fault injection
- Boundary scan register and IEEE 1500 hierarchical wrappers
- At-speed test concepts with an on-chip clock controller

Everything runs with `make`. Every stage has a self-checking testbench.

The repo also includes a structured 16-week curriculum covering scan basics through hierarchical DFT and BISR — with interview talking points for each week.

Built with: Icarus Verilog, Yosys, Fault (AUCOHL).

If you're hiring in DFT, digital design, or silicon validation — I'd love to connect.

GitHub: github.com/glennfrey/open_dft_lec

#DFT #ATPG #VLSI #Semiconductor #DigitalDesign #OpenSourceEDA #CareerGrowth #SemiconductorIndustry #Verilog #Silicon

---

## Version 3: Short / Punchy

Open-source DFT pipeline: synthesis, formal LEC, scan insertion, ATPG, compaction, JTAG TAP, MBIST, boundary scan, hierarchical wrappers, at-speed test.

One `make` command per stage. Self-checking testbenches throughout.

Built with Icarus, Yosys, Fault. Includes 16-week self-study curriculum.

github.com/glennfrey/open_dft_lec

#DFT #VLSI #OpenSourceEDA #Semiconductor #DigitalDesign

---

## Version 4: For DFT-Specific Roles

Most DFT learning happens behind closed doors (Tessent, TetraMAX, Modus).

I built an open-source alternative you can actually run.

open_dft_lec is a complete DFT pipeline on a UART transmitter:

- Synthesis + formal equivalence checking
- Scan insertion, ATPG, pattern compaction
- JTAG TAP controller (IEEE 1149.1)
- Memory BIST with March C- and fault injection
- Boundary scan register (SAMPLE/EXTEST)
- IEEE 1500 hierarchical wrappers (INTEST/EXTEST)
- On-chip clock controller for at-speed test

All verified with self-checking testbenches. All runnable with `make`.

Toolchain: Icarus Verilog, Yosys, Fault (AUCOHL).

Repo: github.com/glennfrey/open_dft_lec

If you're in DFT or silicon test — feedback welcome.

#DFT #ATPG #ScanTest #JTAG #MBIST #BoundaryScan #VLSI #Semiconductor #OpenSourceEDA #SiliconTest

---

## Tips for Posting

1. **Include an image**: Screenshot the flow diagram from the README, or create
a simple block diagram showing the toolchain.
2. **Pin this post** to your profile if it's your strongest project.
3. **Tag people**: If you had mentors or used specific resources, tag them.
4. **Post timing**: Tuesday–Thursday, 8–10 AM or 12–1 PM in your timezone
gets the most semiconductor eyeballs.
5. **Engage with comments**: When someone asks a technical question, answer
it thoroughly — recruiters notice this.