#!/bin/bash

RED='\033[0;31m' GREEN='\033[0;32m' CYAN='\033[0;36m' YELLOW='\033[0;33m' NC='\033[0m'

# Kiểm tra công cụ
for cmd in git curl screen cargo; do
    if ! command -v $cmd &> /dev/null; then
        echo -e "${YELLOW}Cài đặt $cmd...${NC}"
        [ "$cmd" = "cargo" ] && curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y || sudo apt install -y $cmd
    fi
done
source "$HOME/.cargo/env"

echo -e "${CYAN}   ____ ______   _______ ______   _    _ ${NC}"
echo -e "${CYAN}  / __ \  __ \ \ / /_   _|  _ \ | |  | |${NC}"
echo -e "${YELLOW} | |  | | |__) \ V /  | | | |_) || |__| |${NC}"
echo -e "${YELLOW} | |__| |  ___/ > <   | | |  _ < |  __  |${NC}"
echo -e "${CYAN}  \____/|_|    /_/\_| |_| |_| \_|_|  |_|${NC}"
echo -e "Welcome to PETERTRAN! Join: https://t.me/NTExhaust"
sleep 5

echo -e "🚀 Starting..." && rm -rf $HOME/light-node
echo -e "🔗 Cloning..." && git clone https://github.com/Layer-Edge/light-node.git && cd light-node || exit 1
echo -e "📥 Installing..." && curl -L https://risczero.com/install | bash && source "/root/.bashrc"
export GRPC_URL=34.31.74.109:9090 CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709 ZK_PROVER_URL=http://127.0.0.1:3001 API_REQUEST_TIMEOUT=100 POINTS_API=http://127.0.0.1:8080
echo -e "🔑 Enter private key: " && read -s PRIVATE_KEY && echo "export PRIVATE_KEY=$PRIVATE_KEY" >> ~/.bashrc && source ~/.bashrc

echo -e "🛠️ Building risc0..." && cd risc0-merkle-service && cargo build && screen -dmS risc0-service cargo run || exit 1
echo -e "🖥️ Starting light-node..." && cd .. && screen -dmS light-node ./target/debug/light-node || exit 1

echo -e "🎉 Done! Check: screen -ls"
