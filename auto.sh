#!/bin/bash

# ASCII Art Welcome Message by Peter Tran
cat << "EOF"
   ____       _            
  / __ \     (_)           
 | |  | |_ __ _ _ __   ___ 
 | |  | | '__| | '_ \ / _ \
 | |__| | |  | | |_) |  __/
  \____/|_|  |_| .__/___|
               | |         
               |_|         
   LayerEdge Node Setup by Peter Tran
EOF

echo "Welcome Peter Tran to the LayerEdge CLI Light Node setup script!"
echo "This script is customized by Peter Tran - Starting installation now..."
sleep 2

# Step 1: Update system and install dependencies
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl git build-essential pkg-config libssl-dev

# Step 2: Install Go (version 1.21.8)
wget https://go.dev/dl/go1.21.8.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.8.linux-amd64.tar.gz
echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.bashrc
source ~/.bashrc

# Step 3: Install Rust and Risc0 for Zero-Knowledge proofs
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env
cargo install cargo-risczero
risczero install

# Step 4: Clone LayerEdge source code
git clone https://github.com/Layer-Edge/light-node.git
cd light-node

# Step 5: Prompt for Private Key securely
echo "Peter Tran, please enter your Private Key (characters will not be displayed):"
read -s PRIVATE_KEY
if [ -z "$PRIVATE_KEY" ]; then
    echo "Error: Peter Tran, Private Key cannot be empty. Script will exit."
    exit 1
fi

# Step 6: Create .env file with user-provided Private Key
cat <<EOF > .env
GRPC_URL=34.31.74.109:9090
CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709
ZK_PROVER_URL=https://layeredge.mintair.xyz/
API_REQUEST_TIMEOUT=100
POINTS_API=https://light-node.layeredge.io
PRIVATE_KEY=$PRIVATE_KEY
EOF

# Step 7: Build the LayerEdge CLI
go build -o layeredge-cli main.go

# Step 8: Configure systemd service
sudo bash -c "cat <<EOF > /etc/systemd/system/layeredge.service
[Unit]
Description=LayerEdge CLI Light Node by Peter Tran
After=network.target

[Service]
ExecStart=$(pwd)/layeredge-cli
WorkingDirectory=$(pwd)
Restart=always
User=$(whoami)
EnvironmentFile=$(pwd)/.env

[Install]
WantedBy=multi-user.target
EOF"

# Step 9: Start and enable the service
sudo systemctl daemon-reload
sudo systemctl enable layeredge.service
sudo systemctl start layeredge.service

# Final message
echo "Peter Tran, LayerEdge CLI Light Node has been installed and started successfully!"
echo "Check status with: sudo systemctl status layeredge.service"
echo "View logs with: journalctl -u layeredge.service -f"
echo "Thank you for using Peter Tran's script!"
