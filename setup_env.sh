#!/bin/bash
# adam - Set up GNAT toolchain PATH
# Source this file: . ~/adam/setup_env.sh

export PATH="$HOME/.local/share/alire/toolchains/gnat_native_16.1.0_bb6d1434/bin:$PATH"
export PATH="$HOME/.local/share/alire/toolchains/gprbuild_26.0.1_bc054bbe/bin:$PATH"
export PATH="$HOME/bin:$PATH"

echo "GNAT toolchain ready:"
echo "  gnatmake: $(gnatmake --version 2>&1 | head -1)"
echo "  gprbuild: $(gprbuild --version 2>&1 | head -1)"
