#!/bin/bash

# Script cài đặt nút nhẹ LayerEdge trên VPS
# Tác giả: Grok (xAI) - Tạo ngày 22/03/2025

# Màu sắc cho giao diện terminal
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # Không màu

# Hiển thị banner và thông báo chào mừng
echo -e '\e[34m'
echo -e "██████╗ ███████╗████████╗███████╗██████╗ ████████╗██████╗  █████╗ ███╗   ██╗"
echo -e "██╔══██╗██╔════╝╚══██╔══╝██╔════╝██╔══██╗╚══██╔══╝██╔══██╗██╔══██╗████╗  ██║"
echo -e "██████╔╝█████╗     ██║   █████╗  ██████╔╝   ██║   ██████╔╝███████║██╔██╗ ██║"
echo -e "██╔═══╝ ██╔══╝     ██║   ██╔══╝  ██╔══██╗   ██║   ██╔══██╗██╔══██║██║╚██╗██║"
echo -e "██║     ███████╗   ██║   ███████╗██║  ██║   ██║   ██║  ██║██║  ██║██║ ╚████║"
echo -e "╚═╝     ╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝"
echo -e '\e[0m'
echo -e "Chào mừng bạn đến chương trình đu đỉnh node/validator"
sleep 5

echo -e "${GREEN}=== Bắt đầu cài đặt nút nhẹ LayerEdge ===${NC}"

# Kiểm tra quyền root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Vui lòng chạy script này với quyền root (sudo)!${NC}"
  exit 1
fi

# 1. Thiết lập ban đầu
echo -e "${GREEN}Cập nhật hệ thống và cài đặt các gói cơ bản...${NC}"
apt update && apt upgrade -y
apt install -y build-essential git screen nano cargo

# 2. Tạo phiên screen cho dịch vụ Merkle
echo -e "${GREEN}Tạo phiên screen cho dịch vụ Merkle...${NC}"
screen -dmS layeredge

# 3. Sao chép kho lưu trữ light-node
echo -e "${GREEN}Sao chép kho lưu trữ light-node từ GitHub...${NC}"
git clone https://github.com/Layer-Edge/light-node
cd light-node || { echo -e "${RED}Không thể vào thư mục light-node${NC}"; exit 1; }

# 4. Cài đặt Go (phiên bản 1.21.6)
echo -e "${GREEN}Cài đặt Go 1.21.6...${NC}"
wget https://go.dev/dl/go1.21.6.linux-amd64.tar.gz
tar -C /usr/local -xzf go1.21.6.linux-amd64.tar.gz
echo "export GOROOT=/usr/local/go" >> ~/.bashrc
echo "export GOPATH=\$HOME/go" >> ~/.bashrc
echo "export PATH=\$GOPATH/bin:\$GOROOT/bin:\$PATH" >> ~/.bashrc
source ~/.bashrc
go version || { echo -e "${RED}Cài đặt Go thất bại${NC}"; exit 1; }

# 5. Cài đặt Rust và Risc0 Toolchain
echo -e "${GREEN}Cài đặt Rust...${NC}"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env

echo -e "${GREEN}Cài đặt Risc0 Toolchain...${NC}"
curl -L https://risczero.com/install | bash
source "/root/.bashrc"
rzup install
source "/root/.bashrc"

# 6. Cấu hình tệp .env
echo -e "${GREEN}Tạo và cấu hình tệp .env...${NC}"
echo -e "Vui lòng nhập khóa riêng EVM của bạn (khuyến nghị sử dụng ví burner):"
read -s PRIVATE_KEY

# Kiểm tra xem PRIVATE_KEY có rỗng không
if [ -z "$PRIVATE_KEY" ]; then
  echo -e "${RED}Khóa riêng không được để trống! Thoát chương trình.${NC}"
  exit 1
fi

# Tự động tạo tệp .env với khóa riêng người dùng nhập
cat <<EOF > .env
GRPC_URL=grpc.testnet.layeredge.io:9090
CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709
ZK_PROVER_URL=http://127.0.0.1:3001
API_REQUEST_TIMEOUT=100
POINTS_API=light-node.layeredge.io
PRIVATE_KEY=$PRIVATE_KEY
EOF

echo -e "${GREEN}Tệp .env đã được tạo thành công với khóa riêng của bạn!${NC}"
