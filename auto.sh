#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m'

# Cài đặt công cụ nếu thiếu
for cmd in git curl screen cargo; do
    if ! command -v $cmd &> /dev/null; then
        echo -e "${YELLOW}📦 Cài đặt $cmd...${NC}"
        if [ "$cmd" = "cargo" ]; then
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
            source "$HOME/.cargo/env"
        else
            sudo apt update && sudo apt install -y $cmd
        fi
    fi
done

echo -e "${CYAN}   ____ ______   _______ ______   _    _ ${NC}"
echo -e "${CYAN}  / __ \  __ \ \ / /_   _|  _ \ | |  | |${NC}"
echo -e "${YELLOW} | |  | | |__) \ V /  | | | |_) || |__| |${NC}"
echo -e "${YELLOW} | |__| |  ___/ > <   | | |  _ < |  __  |${NC}"
echo -e "${CYAN}  \____/|_|    /_/\_| |_| |_| \_|_|  |_|${NC}"
echo -e "Welcome to PETERTRAN! Join Telegram: https://t.me/NTExhaust"
sleep 5

echo -e "🚀 Starting setup process..."
rm -rf $HOME/light-node
echo -e "🔗 Cloning repository..."
git clone https://github.com/Layer-Edge/light-node.git && echo -e "✅ Repository cloned!" || { echo -e "${RED}❌ Clone thất bại!${NC}"; exit 1; }
cd light-node
echo -e "📥 Downloading and installing dependencies..."
curl -L https://risczero.com/install | bash && echo -e "✅ Dependencies installed!"
source "/root/.bashrc"
echo -e "🔄 Applying environment variables..."
export GRPC_URL=34.31.74.109:9090
export CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709
export ZK_PROVER_URL=http://127.0.0.1:3001
export API_REQUEST_TIMEOUT=100
export POINTS_API=http://127.0.0.1:8080
echo -e "🔑 Please enter your private key: "
read -s PRIVATE_KEY
echo "export PRIVATE_KEY=$PRIVATE_KEY" >> $HOME/.lightnode_config
source $HOME/.lightnode_config
echo -e "✅ Private key set securely!"

echo -e "🛠️ Building and running risc0-merkle-service..."
cd risc0-merkle-service
cargo build && screen -dmS risc0-service cargo run && echo -e "🚀 risc0-merkle-service is running!" || { echo -e "${RED}❌ Build thất bại!${NC}"; exit 1; }

echo -e "🖥️ Starting light-node server..."
cd .. && screen -dmS light-node ./target/debug/light-node && echo "✅ Light node started!" || { echo -e "${RED}❌ Light-node thất bại!${NC}"; exit 1; }

echo -e "🎉 Setup complete! Both servers are running in screen sessions!"
