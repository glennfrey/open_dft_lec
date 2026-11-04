#!/usr/bin/env bash
# install.sh -- Open DFT + LEC toolchain installer (Ubuntu/Debian)
# Tested strategy: Ubuntu 22.04/24.04 LTS. Run: bash install.sh
set -euo pipefail

echo "=== [1/4] Core EDA tools (apt) ==="
sudo apt update
sudo apt install -y \
    yosys \
    iverilog \
    gtkwave \
    git make curl

echo "=== [2/4] Fault DFT toolchain (pip) ==="
# Fault needs Python >=3.8; uses jinja2 + yosys/iverilog binaries from step 1
sudo apt install -y python3 python3-pip python3-venv
python3 -m venv ~/.venv-dft
source ~/.venv-dft/bin/activate
pip install --upgrade pip
pip install fault

echo "=== [3/4] Atalanta PODEM ATPG (optional, free for non-commercial use) ==="
echo "Skip by default - proprietary for commercial use. To enable:"
echo "  git clone https://github.com/Atalanta-Research/atalanta && cd atalanta && make"

echo "=== [4/4] Verify installation ==="
yosys -V
iverilog -V | head -1
python3 -c "import fault; print('fault OK')"
which fault

echo ""
echo "============================================="
echo " Installation complete. Next steps:"
echo "   1. echo 'source ~/.venv-dft/bin/activate' >> ~/.bashrc"
echo "   2. cd open_dft_lec && make sim && make lec"
echo "============================================="
