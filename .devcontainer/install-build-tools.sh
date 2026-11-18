
#!/usr/bin/env bash
set -euo pipefail

echo "Installing build dependencies..."
sudo apt-get update
sudo apt-get install -y \
    git \
    python3 \
    python3-venv \
    build-essential \
    cmake

# Install SCons in an isolated Python environment
echo "Installing SCons..."
python3 -m venv "$HOME/.scons-venv"
"$HOME/.scons-venv/bin/pip" install --upgrade scons

# Install Emscripten
echo "Installing Emscripten..."
if [ ! -d "$HOME/emsdk" ]; then
    git clone https://github.com/emscripten-core/emsdk.git "$HOME/emsdk"
fi

cd "$HOME/emsdk"
./emsdk install latest
./emsdk activate latest

# Configure Bash for future terminal sessions
if ! grep -q 'source "$HOME/emsdk/emsdk_env.sh"' "$HOME/.bashrc"; then
    echo 'source "$HOME/emsdk/emsdk_env.sh" >/dev/null' >> "$HOME/.bashrc"
fi

if ! grep -q 'scons-venv/bin' "$HOME/.bashrc"; then
    echo 'export PATH="$HOME/.scons-venv/bin:$PATH"' >> "$HOME/.bashrc"
fi

# Enable tools for this script
source "$HOME/emsdk/emsdk_env.sh" >/dev/null
export PATH="$HOME/.scons-venv/bin:$PATH"

echo "Installation complete!"
emcc --version
scons --version
