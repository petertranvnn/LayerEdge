#!/bin/bash

# Màu sắc cho output
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m'

# Hàm hiển thị banner PETERTRAN
display_banner() {
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
    echo -e "Tham gia Telegram của chúng tôi: ${YELLOW}https://t.me/VietNameseAirdrop${NC}"
    sleep 3
}

# Kiểm tra hệ điều hành
check_os() {
    if [[ ! -f /etc/os-release ]]; then
        echo -e "${RED}Cannot detect OS. This script is designed for Ubuntu 22.04.${NC}"
        exit 1
    fi
    . /etc/os-release
    if [[ "$ID" != "ubuntu" || "$VERSION_ID" != "22.04" ]]; then
        echo -e "${RED}This script is designed for Ubuntu 22.04 only. Detected: $ID $VERSION_ID${NC}"
        exit 1
    fi
    echo -e "${GREEN}Ubuntu 22.04 detected. Proceeding...${NC}"
}

# Cài đặt các phụ thuộc cần thiết
install_dependencies() {
    echo -e "${YELLOW}Updating system and installing dependencies...${NC}"
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y git curl build-essential screen

    # Cài đặt Go
    if ! command -v go &> /dev/null || [[ $(go version | cut -d" " -f3 | cut -c 3-6) < "1.18" ]]; then
        echo -e "${YELLOW}Installing Go 1.21...${NC}"
        wget https://go.dev/dl/go1.21.8.linux-amd64.tar.gz
        sudo tar -C /usr/local -xzf go1.21.8.linux-amd64.tar.gz
        echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.bashrc
        source ~/.bashrc
        rm go1.21.8.linux-amd64.tar.gz
    fi
    echo -e "${GREEN}Go version: $(go version)${NC}"

    # Cài đặt Rust
    if ! command -v rustc &> /dev/null || [[ $(rustc --version | cut -d" " -f2) < "1.81" ]]; then
        echo -e "${YELLOW}Installing Rust...${NC}"
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    fi
    echo -e "${GREEN}Rust version: $(rustc --version)${NC}"

    # Cài đặt Risc0 Toolchain
    echo -e "${YELLOW}Installing Risc0 Toolchain...${NC}"
    curl -L https://risczero.com/install | bash
    rzup install
}

# Thiết lập node
setup_node() {
    echo -e "${YELLOW}Cloning LayerEdge Light Node repository...${NC}"
    rm -rf ~/light-node
    git clone https://github.com/Layer-Edge/light-node.git
    cd ~/light-node || exit

    # Nhập private key từ người dùng
    echo -e "${CYAN}Please enter your private key:${NC}"
    read -s PRIVATE_KEY
    echo -e "${GREEN}Private key set!${NC}"

    # Thiết lập biến môi trường
    echo -e "${YELLOW}Configuring environment variables...${NC}"
    cat << EOF > .env
GRPC_URL=grpc.testnet.layeredge.io:9090
CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709
ZK_PROVER_URL=http://127.0.0.1:3001
API_REQUEST_TIMEOUT=100
POINTS_API=https://light-node.layeredge.io
PRIVATE_KEY=$PRIVATE_KEY
EOF
    echo -e "${GREEN}Environment variables configured!${NC}"

    # Build và chạy Merkle Service
    echo -e "${YELLOW}Building and starting Merkle Service...${NC}"
    cd risc0-merkle-service
    cargo build
    screen -dmS merkle-service cargo run
    sleep 5
    echo -e "${GREEN}Merkle Service is running in a screen session!${NC}"

    # Build và chạy Light Node
    echo -e "${YELLOW}Building and starting Light Node...${NC}"
    cd ~/light-node
    go build
    screen -dmS light-node ./light-node
    echo -e "${GREEN}Light Node is running in a screen session!${NC}"
}

# Hiển thị thông tin hoàn tất
finish_setup() {
    echo -e "${GREEN}Setup complete!${NC}"
    echo -e " - Merkle Service is running in screen session 'merkle-service'"
    echo -e " - Light Node is running in screen session 'light-node'"
    echo -e "To check the services:"
    echo -e "  - Access Merkle Service: ${CYAN}screen -r merkle-service${NC}"
    echo -e "  - Access Light Node: ${CYAN}screen -r light-node${NC}"
    echo -e "  - Detach from screen: Press ${CYAN}Ctrl+A then D${NC}"
    echo -e "Tham gia Telegram của chúng tôi: ${YELLOW}https://t.me/VietNameseAirdrop${NC}"
}

# Chạy các bước chính
main() {
    display_banner
    check_os
    install_dependencies
    setup_node
    finish_setup
}

# Thực thi script
main
