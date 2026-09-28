# Installation Guide — Open DFT + LEC Toolchain

Target OS: **Ubuntu 22.04 LTS or 24.04 LTS** (other Debian-based distros work;
Fedora/Arch need equivalent package names). Windows users: use WSL2 + Ubuntu.

## Strategy overview

| Layer | Tools | Method | Why this order |
|---|---|---|---|
| 1 | Yosys, Icarus Verilog, GTKWave | `apt` | Fault (layer 2) shells out to these binaries |
| 2 | Fault (DFT/ATPG) | `pip` in a venv | Python orchestrator; needs `yosys` + `iverilog` present |
| 3 | OpenLane/OpenROAD (optional) | Docker | Nightly builds move fast; container avoids dependency hell |
| 4 | Atalanta PODEM (optional) | build from source | Free for non-commercial use only |

## Quick start

```bash
bash install.sh          # layers 1+2, ~5-10 min on broadband
```

Then activate the venv in every new terminal (or add to ~/.bashrc):

```bash
source ~/.venv-dft/bin/activate
cd open_dft_lec
make sim    # expect: TESTBENCH PASSED
make synth  # builds build/uart_tx_synth.v
make lec    # expect: equiv_status all proven, exit 0
make dft    # fault synth/cut/atpg/compact/chain/tap
```

## Detailed per-tool notes

### Yosys (synthesis + formal LEC)
- `apt install yosys` gives a solid release (0.3x series) — sufficient for
  `equiv_make/equiv_simple/equiv_status` and `sat`.
- Need newer? Build from source (https://github.com/YosysHQ/yosys) — only if
  a specific feature is missing; apt version is fine for this project.

### Icarus Verilog (simulation)
- `apt install iverilog`. Verilator (`apt install verilator`) is a faster
  alternative but Icarus is what Fault uses internally — install both.

### GTKWave (waveforms)
- `apt install gtkwave`. View the VCD from the testbench:
  `gtkwave uart_tx_tb.vcd` — useful when debugging scan-shift waveforms.

### Fault (the DFT toolchain)
- Lives in a Python venv (`~/.venv-dft`) to avoid PEP 668 "externally managed
  environment" errors on Ubuntu 23.04+/24.04. **Do not** `sudo pip install`.
- If `pip install fault` fails, build from source:
  ```bash
  git clone https://github.com/AUCOHL/Fault && cd Fault
  pip install -e .
  ```
- Verify flags against your release: `fault synth -h`, `fault atpg -h`, etc.
  (flag names have changed between releases).

### Atalanta (optional PODEM ATPG)
- Clone https://github.com/Atalanta-Research/atalanta, `make`. Ancient C
  codebase — may need `sudo apt install bison flex`.
- Remember: free for learning/research, **proprietary for commercial use**
  (fine for this portfolio project).

### OpenLane 2 / OpenROAD (optional, stretch goal)
- Docker only:
  ```bash
  docker pull efabless/openlane2:latest
  ```
- Full instructions: https://openlane2.readthedocs.io — do this only after
  layers 1+2 work end-to-end.

## Version pinning for reproducibility

Your DFT sign-off report §3 asks for tool versions. Capture them once:

```bash
yosys -V > build/versions.txt
iverilog -V | head -1 >> build/versions.txt
pip freeze | grep -i fault >> build/versions.txt
```

## Troubleshooting

| Symptom | Fix |
|---|---|
| `error: externally-managed-environment` (pip) | Use the venv — never `sudo pip` on Ubuntu 24.04 |
| `fault: command not found` | Forgot `source ~/.venv-dft/bin/activate` |
| `yosys: command not found` inside Fault | Install layer 1 first; Fault needs the binary on PATH |
| `abc` errors during synth | Old yosys — `sudo apt upgrade yosys` or build from source |
| Fault flag rejected | `fault <cmd> -h` — adjust Makefile flags for your release |
| WSL: GTKWave won't open | Run `wsl --update`, or use `gtkwave` with VcXsrv/X server, or analyze VCD textually |

## Post-install checklist

- [ ] `yosys -V` prints a version
- [ ] `iverilog` compiles the testbench (`make sim` → TESTBENCH PASSED)
- [ ] `fault` runs `fault synth -h`
- [ ] `make lec` exits 0
- [ ] Versions saved to `build/versions.txt`
