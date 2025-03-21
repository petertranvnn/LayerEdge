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
echo -e "Tham gia Telegram của chúng tôi: ${YELLOW}https://t.me/VietNameseAirdrop${NC}"
sleep 3

# Kiểm tra hệ điều hành
if [[ ! $(lsb_release -rs) =~ "22.04" ]]; then
    echo -e "${RED}Lỗi: Script này chỉ được thiết kế cho Ubuntu 22.04.${NC}"
    exit 1
fi

# Cập nhật hệ thống và cài đặt các gói cần thiết
echo -e "${YELLOW}🚀 Đang cập nhật hệ thống và cài đặt các gói cần thiết...${NC}"
sudo apt update && sudo apt upgrade -y
sudo apt install -y git curl build-essential screen

# Cài đặt Go
echo -e "${YELLOW}📦 Đang cài đặt Go...${NC}"
wget -q https://go.dev/dl/go1.21.8.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.8.linux-amd64.tar.gz
echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.bashrc
source ~/.bashrc
rm go1.21.8.linux-amd64.tar.gz

# Cài đặt Rust và Risc0
echo -e "${YELLOW}📥 Đang cài đặt Rust và Risc0...${NC}"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"
curl -L https://risczero.com/install | bash
rzup install

# Xóa thư mục cũ nếu tồn tại và clone repository mới
echo -e "${YELLOW}🔗 Đang clone repository LayerEdge Light Node...${NC}"
rm -rf ~/light-node
git clone https://github.com/Layer-Edge/light-node.git
cd ~/light-node || exit

# Nhập private key từ người dùng
echo -e "${CYAN}🔑 Vui lòng nhập private key của bạn:${NC}"
read -s PRIVATE_KEY
if [ -z "$PRIVATE_KEY" ]; then
    echo -e "${RED}Lỗi: Private key không được để trống.${NC}"
    exit 1
fi

# Thiết lập biến môi trường
echo -e "${YELLOW}🔄 Đang thiết lập biến môi trường...${NC}"
cat > .env << EOL
GRPC_URL=grpc.testnet.layeredge.io:9090
CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709
ZK_PROVER_URL=http://127.0.0.1:3001
API_REQUEST_TIMEOUT=100
POINTS_API=https://light-node.layeredge.io
PRIVATE_KEY=$PRIVATE_KEY
EOL

# Build và chạy Merkle Service
echo -e "${YELLOW}🛠️ Đang build và khởi động Merkle Service...${NC}"
cd risc0-merkle-service || exit
cargo build
screen -dmS merkle-service bash -c "cargo run; exec bash"
sleep 5

# Build và chạy Light Node
echo -e "${YELLOW}🖥️ Đang build và khởi động Light Node...${NC}"
cd ~/light-node || exit
go build
screen -dmS light-node bash -c "./light-node; exec bash"

# Kiểm tra trạng thái
echo -e "${GREEN}🎉 Hoàn tất cài đặt! Đang kiểm tra trạng thái...${NC}"
sleep 5
if screen -list | grep -q "merkle-service" && screen -list | grep -q "light-node"; then
    echo -e "${GREEN}✅ Cả Merkle Service và Light Node đang chạy trong các phiên screen!${NC}"
else
    echo -e "${RED}⚠️ Có lỗi xảy ra. Kiểm tra các phiên screen bằng 'screen -list'.${NC}"
fi

# Hướng dẫn sử dụng
echo -e "${CYAN}ℹ️ Các lệnh hữu ích:${NC}"
echo -e "  - Xem các phiên đang chạy: ${YELLOW}screen -list${NC}"
echo -e "  - Truy cập Merkle Service: ${YELLOW}screen -r merkle-service${NC}"
echo -e "  - Truy cập Light Node: ${YELLOW}screen -r light-node${NC}"
echo -e "  - Thoát khỏi screen: ${YELLOW}Ctrl+A rồi D${NC}"
echo -e "Tham gia Telegram để được hỗ trợ: ${YELLOW}https://t.me/NTExhaust${NC}"
