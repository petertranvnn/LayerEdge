#!/bin/bash

# Màu sắc cho giao diện
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m'

# Hiển thị banner "PETERTRAN"
clear
echo -e '\e[34m'
echo -e "██████╗ ███████╗████████╗███████╗██████╗ ████████╗██████╗  █████╗ ███╗   ██╗"
echo -e "██╔══██╗██╔════╝╚══██╔══╝██╔════╝██╔══██╗╚══██╔══╝██╔══██╗██╔══██╗████╗  ██║"
echo -e "██████╔╝█████╗     ██║   █████╗  ██████╔╝   ██║   ██████╔╝███████║██╔██╗ ██║"
echo -e "██╔═══╝ ██╔══╝     ██║   ██╔══╝  ██╔══██╗   ██║   ██╔══██╗██╔══██║██║╚██╗██║"
echo -e "██║     ███████╗   ██║   ███████╗██║  ██║   ██║   ██║  ██║██║  ██║██║ ╚████║"
echo -e "╚═╝     ╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝"
echo -e '\e[0m'
echo -e "${CYAN}Chào mừng bạn đến với script cài đặt của PETERTRAN${NC}"
echo -e "Join our Telegram: ${YELLOW}https://t.me/NTExhaust${NC}"
sleep 3

# Kiểm tra hệ điều hành
if [[ ! $(lsb_release -rs) =~ "22.04" ]]; then
    echo -e "${RED}Error: This script is designed for Ubuntu 22.04 only.${NC}"
    exit 1
fi

# Cập nhật hệ thống và cài đặt các gói cần thiết
echo -e "${YELLOW}🚀 Updating system and installing prerequisites...${NC}"
sudo apt update && sudo apt upgrade -y
sudo apt install -y git curl build-essential screen

# Cài đặt Go
echo -e "${YELLOW}📦 Installing Go...${NC}"
wget -q https://go.dev/dl/go1.21.8.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.8.linux-amd64.tar.gz
echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.bashrc
source ~/.bashrc
rm go1.21.8.linux-amd64.tar.gz

# Cài đặt Rust và Risc0
echo -e "${YELLOW}📥 Installing Rust and Risc0...${NC}"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"
curl -L https://risczero.com/install | bash
rzup install

# Xóa thư mục cũ nếu tồn tại và clone repository mới
echo -e "${YELLOW}🔗 Cloning LayerEdge Light Node repository...${NC}"
rm -rf ~/light-node
git clone https://github.com/Layer-Edge/light-node.git
cd ~/light-node || exit

# Nhập private key từ người dùng
echo -e "${CYAN}🔑 Please enter your private key:${NC}"
read -s PRIVATE_KEY
if [ -z "$PRIVATE_KEY" ]; then
    echo -e "${RED}Error: Private key cannot be empty.${NC}"
    exit 1
fi

# Thiết lập biến môi trường
echo -e "${YELLOW}🔄 Setting up environment variables...${NC}"
cat > .env << EOL
GRPC_URL=grpc.testnet.layeredge.io:9090
CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709
ZK_PROVER_URL=http://127.0.0.1:3001
API_REQUEST_TIMEOUT=100
POINTS_API=https://light-node.layeredge.io
PRIVATE_KEY=$PRIVATE_KEY
EOL

# Build và chạy Merkle Service
echo -e "${YELLOW}🛠️ Building and starting Merkle Service...${NC}"
cd risc0-merkle-service || exit
cargo build
screen -dmS merkle-service bash -c "cargo run; exec bash"
sleep 5

# Build và chạy Light Node
echo -e "${YELLOW}🖥️ Building and starting Light Node...${NC}"
cd ~/light-node || exit
go build
screen -dmS light-node bash -c "./light-node; exec bash"

# Kiểm tra trạng thái
echo -e "${GREEN}🎉 Setup complete! Checking status...${NC}"
sleep 5
if screen -list | grep -q "merkle-service" && screen -list | grep -q "light-node"; then
    echo -e "${GREEN}✅ Both Merkle Service and Light Node are running in screen sessions!${NC}"
else
    echo -e "${RED}⚠️ Something went wrong. Check screen sessions with 'screen -list'.${NC}"
fi

# Hướng dẫn sử dụng
echo -e "${CYAN}ℹ️ Useful commands:${NC}"
echo -e "  - View running sessions: ${YELLOW}screen -list${NC}"
echo -e "  - Access Merkle Service: ${YELLOW}screen -r merkle-service${NC}"
echo -e "  - Access Light Node: ${YELLOW}screen -r light-node${NC}"
echo -e "  - Detach from screen: ${YELLOW}Ctrl+A then D${NC}"
echo -e "Join Telegram for support: ${YELLOW}https://t.me/NTExhaust${NC}"
