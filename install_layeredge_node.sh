#!/bin/bash

# Update system packages
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Ensure required packages are installed
sudo apt install -y lsof curl git screen

# Remove old Go version if it exists
echo "Removing old Go version..."
sudo rm -rf /usr/local/go

# Install Go (version 1.23.1)
echo "Installing Go 1.23.1..."
wget https://go.dev/dl/go1.23.1.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.23.1.linux-amd64.tar.gz
echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.bashrc
source ~/.bashrc

# Verify Go installation
go version || { echo "Go installation failed! Exiting..."; exit 1; }

# Install Rust
echo "Installing Rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env

# Verify Rust installation
rustc --version || { echo "Rust installation failed! Exiting..."; exit 1; }

# Install Risc0 Toolchain
echo "Installing Risc0 Toolchain..."
curl -L https://risczero.com/install | bash

# Add Risc0 to PATH and install
export PATH=$PATH:/root/.risc0/bin
/root/.risc0/bin/rzup install || { echo "Risc0 installation failed! Exiting..."; exit 1; }

# Prompt the user for their private key securely
read -sp "Please enter your private key: " PRIVATE_KEY
echo  # Move to a new line after input
echo "Private key recorded."

# Check if LayerEdge repo exists
if [ -d "light-node" ]; then
    echo "LayerEdge light node directory already exists. Skipping clone..."
    cd light-node
else
    echo "Cloning LayerEdge light node repository..."
    git clone https://github.com/Layer-Edge/light-node.git
    cd light-node
fi

# Create .env file inside the project directory
echo "Creating .env file..."
cat <<EOF > .env
GRPC_URL=34.31.74.109:9090
CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709
ZK_PROVER_URL=http://127.0.0.1:3001
API_REQUEST_TIMEOUT=100
POINTS_API=http://127.0.0.1:8080
PRIVATE_KEY=$PRIVATE_KEY
EOF

# Set proper permissions and output the file for debugging
chmod 644 .env
echo "Contents of .env file:"
cat .env

# Optionally convert to Unix line endings if dos2unix is available
if command -v dos2unix &>/dev/null; then
    dos2unix .env
fi

# Verify .env file exists
if [ ! -f ".env" ]; then
    echo "Error: .env file was not created! Exiting..."
    exit 1
fi

# Kill any process using port 3001
PORT=3001
PID=$(lsof -ti:$PORT)
if [ -n "$PID" ]; then
    echo "Port $PORT is in use. Killing process..."
    kill -9 $PID
fi

# Start the Merkle service
echo "Starting the Merkle service..."
cd risc0-merkle-service
cargo build
cargo run &

# Return to the light-node directory
cd ..

# Load the .env file before running the node
echo "Loading environment variables from .env..."
set -o allexport
source .env
set +o allexport

# Build and run the LayerEdge light node
echo "Building and running the LayerEdge light node..."
go build || { echo "Go build failed! Exiting..."; exit 1; }

# Run the light-node
./light-node &

echo "LayerEdge light node setup complete!"
