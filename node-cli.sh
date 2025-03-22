#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Banner mới
echo -e "${BLUE}"
echo -e "██████╗ ███████╗████████╗███████╗██████╗ ████████╗██████╗  █████╗ ███╗   ██╗"
echo -e "██╔══██╗██╔════╝╚══██╔══╝██╔════╝██╔══██╗╚══██╔══╝██╔══██╗██╔══██╗████╗  ██║"
echo -e "██████╔╝█████╗     ██║   █████╗  ██████╔╝   ██║   ██████╔╝███████║██╔██╗ ██║"
echo -e "██╔═══╝ ██╔══╝     ██║   ██╔══╝  ██╔══██╗   ██║   ██╔══██╗██╔══██║██║╚██╗██║"
echo -e "██║     ███████╗   ██║   ███████╗██║  ██║   ██║   ██║  ██║██║  ██║██║ ╚████║"
echo -e "╚═╝     ╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝"
echo -e "${NC}"
echo -e "${GREEN}Chào mừng bạn đến với LayerEdge Light Node!${NC}"
sleep 5

# Cập nhật hệ thống và cài đặt công cụ cơ bản
echo -e "${YELLOW}🚀 Updating system and installing basic tools...${NC}"
apt update && apt upgrade -y || { echo -e "${RED}❌ Failed to update system${NC}"; exit 1; }
apt install -y git curl screen build-essential || { echo -e "${RED}❌ Failed to install tools${NC}"; exit 1; }

# Cài đặt Go
echo -e "${CYAN}📥 Installing Go...${NC}"
wget https://go.dev/dl/go1.21.6.linux-amd64.tar.gz || { echo -e "${RED}❌ Failed to download Go${NC}"; exit 1; }
sudo tar -C /usr/local -xzf go1.21.6.linux-amd64.tar.gz
echo "export GOROOT=/usr/local/go" >> ~/.bashrc
echo "export GOPATH=\$HOME/go" >> ~/.bashrc
echo "export PATH=\$GOPATH/bin:\$GOROOT/bin:\$PATH" >> ~/.bashrc
source ~/.bashrc
go version && echo -e "${GREEN}✅ Go installed: $(go version)${NC}"

# Cài đặt Rust
echo -e "${CYAN}📥 Installing Rust...${NC}"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y || { echo -e "${RED}❌ Failed to install Rust${NC}"; exit 1; }
source $HOME/.cargo/env
rustc --version && echo -e "${GREEN}✅ Rust installed: $(rustc --version)${NC}"

# Cài đặt Risc Zero
echo -e "${CYAN}📥 Installing Risc Zero...${NC}"
curl -L https://risczero.com/install | bash || { echo -e "${RED}❌ Failed to install Risc Zero${NC}"; exit 1; }
rzup install || { echo -e "${RED}❌ Failed to install rzup${NC}"; exit 1; }
rzup --version && echo -e "${GREEN}✅ Risc Zero installed${NC}"

# Tải mã nguồn
echo -e "${YELLOW}🔗 Cloning LayerEdge light-node repository...${NC}"
rm -rf $HOME/light-node
git clone https://github.com/Layer-Edge/light-node.git $HOME/light-node || { echo -e "${RED}❌ Failed to clone repository${NC}"; exit 1; }
cd $HOME/light-node

# Tạo file .env và yêu cầu nhập thủ công private key
echo -e "${CYAN}🔄 Setting up environment variables...${NC}"
cat << EOF > .env
GRPC_URL=grpc.testnet.layeredge.io:9090
CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709
ZK_PROVER_URL=http://127.0.0.1:3001
API_REQUEST_TIMEOUT=100
POINTS_API=light-node.layeredge.io
PRIVATE_KEY=
EOF
echo -e "${YELLOW}🔑 Please enter your private key manually:${NC}"
read -p "Enter your private key: " PRIVATE_KEY
echo "PRIVATE_KEY=$PRIVATE_KEY" >> .env
echo -e "${GREEN}✅ Environment variables set with your private key!${NC}"

# Biên dịch và chạy risc0-merkle-service
echo -e "${YELLOW}🛠️ Building and running risc0-merkle-service...${NC}"
cd risc0-merkle-service
cargo build --release || { echo -e "${RED}❌ Failed to build risc0-merkle-service${NC}"; exit 1; }
screen -dmS risc0-service cargo run --release || { echo -e "${RED}❌ Failed to start risc0-service${NC}"; exit 1; }
echo -e "${GREEN}🚀 risc0-merkle-service is running in screen session 'risc0-service'${NC}"

# Biên dịch và chạy light-node
echo -e "${YELLOW}🖥️ Building and running light-node...${NC}"
cd $HOME/light-node
go build || { echo -e "${RED}❌ Failed to build light-node${NC}"; exit 1; }
screen -dmS light-node ./light-node || { echo -e "${RED}❌ Failed to start light-node${NC}"; exit 1; }
echo -e "${GREEN}🚀 light-node is running in screen session 'light-node'${NC}"

# Hoàn tất
echo -e "${GREEN}🎉 Setup complete! Both services are running in screen sessions!${NC}"
echo -e "Check them with: ${GREEN}screen -r risc0-service${NC} or ${GREEN}screen -r light-node${NC}"
echo -e "View all sessions: ${GREEN}screen -ls${NC}"
