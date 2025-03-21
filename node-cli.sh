#!/bin/bash

# Script cài đặt nút nhẹ LayerEdge trên VPS
# Dựa trên hướng dẫn từ người dùng - Tạo ngày 22/03/2025

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
apt install -y build-essential git screen

# 2. Tạo phiên screen cho dịch vụ Merkle
echo -e "${GREEN}Tạo phiên screen cho dịch vụ Merkle...${NC}"
screen -dmS layeredge

# 3. Sao chép kho lưu trữ light-node
echo -e "${GREEN}Sao chép kho lưu trữ light-node từ GitHub...${NC}"
if [ -d "light-node" ]; then
  echo -e "${RED}Thư mục light-node đã tồn tại, đang xóa...${NC}"
  rm -rf light-node
fi
git clone https://github.com/Layer-Edge/light-node
cd light-node || { echo -e "${RED}Không thể vào thư mục light-node${NC}"; exit 1; }

# 4. Cài đặt các phụ thuộc
# Cài đặt Go 1.21.6
echo -e "${GREEN}Cài đặt Go 1.21.6...${NC}"
if ! command -v go &> /dev/null; then
  wget https://go.dev/dl/go1.21.6.linux-amd64.tar.gz
  tar -C /usr/local -xzf go1.21.6.linux-amd64.tar.gz
  rm go1.21.6.linux-amd64.tar.gz
fi
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH
echo "export GOROOT=/usr/local/go" >> ~/.bashrc
echo "export GOPATH=\$HOME/go" >> ~/.bashrc
echo "export PATH=\$GOPATH/bin:\$GOROOT/bin:\$PATH" >> ~/.bashrc
go version || { echo -e "${RED}Cài đặt Go thất bại${NC}"; exit 1; }

# Cài đặt Rust
if ! command -v rustc &> /dev/null; then
  echo -e "${GREEN}Cài đặt Rust...${NC}"
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  source $HOME/.cargo/env
else
  echo -e "${GREEN}Rust đã được cài đặt, đang cập nhật lên phiên bản mới nhất...${NC}"
  rustup update
fi
rustc --version || { echo -e "${RED}Cài đặt hoặc cập nhật Rust thất bại${NC}"; exit 1; }

# Cài đặt Risc0 Toolchain
echo -e "${GREEN}Cài đặt Risc0 Toolchain...${NC}"
curl -L https://risczero.com/install | bash
export PATH=$PATH:/root/.risc0/bin
rzup install || { echo -e "${RED}Cài đặt Risc0 Toolchain thất bại${NC}"; exit 1; }

# Cài đặt Cargo (nếu chưa có)
if ! command -v cargo &> /dev/null; then
  echo -e "${GREEN}Cài đặt Cargo...${NC}"
  apt install -y cargo
fi

# 5. Cấu hình tệp .env với thời gian dừng và yêu cầu nhập private key
echo -e "${GREEN}Tạo và cấu hình tệp .env...${NC}"
echo -e "${GREEN}Chuẩn bị khóa riêng EVM của bạn (khuyến nghị sử dụng ví burner).${NC}"
echo -e "Nhấn Enter khi bạn đã sẵn sàng nhập khóa riêng để tiếp tục..."
read -p ""

PRIVATE_KEY=""
while [ -z "$PRIVATE_KEY" ]; do
  echo -e "Vui lòng nhập khóa riêng EVM của bạn (khóa không được để trống):"
  read -s PRIVATE_KEY
  if [ -z "$PRIVATE_KEY" ]; then
    echo -e "${RED}Khóa riêng không được để trống! Vui lòng nhập lại.${NC}"
  fi
done

# Tạo tệp .env
cat <<EOF > .env
GRPC_URL=grpc.testnet.layeredge.io:9090
CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709
ZK_PROVER_URL=http://127.0.0.1:3001
API_REQUEST_TIMEOUT=100
POINTS_API=light-node.layeredge.io
PRIVATE_KEY=$PRIVATE_KEY
EOF
echo -e "${GREEN}Tệp .env đã được tạo thành công!${NC}"

# 6. Chạy dịch vụ Merkle
echo -e "${GREEN}Xây dựng và chạy dịch vụ Merkle...${NC}"
cd risc0-merkle-service || { echo -e "${RED}Không tìm thấy thư mục risc0-merkle-service${NC}"; exit 1; }
cargo build || { echo -e "${RED}Xây dựng dịch vụ Merkle thất bại${NC}"; exit 1; }
screen -S layeredge -X stuff "cargo run\n"  # Chạy trong screen đã tạo
echo -e "${GREEN}Dịch vụ Merkle đang chạy trong screen 'layeredge'. Để kiểm tra, dùng: screen -r layeredge${NC}"
sleep 5  # Đợi để dịch vụ khởi động

# 7. Xây dựng và chạy nút nhẹ
echo -e "${GREEN}Xây dựng và chạy nút nhẹ LayerEdge...${NC}"
cd ../
screen -dmS light-node
go build || { echo -e "${RED}Xây dựng nút nhẹ thất bại${NC}"; exit 1; }
screen -S light-node -X stuff "./light-node\n"  # Chạy trong screen mới

# 8. Hiển thị thông báo hoàn tất
echo -e "${GREEN}=== Cài đặt hoàn tất! ===${NC}"
echo "Kiểm tra trạng thái:"
echo "- Dịch vụ Merkle: screen -r layeredge"
echo "- Nút nhẹ: screen -r light-node"
echo "Lưu ý: Sao chép khóa công khai từ logs trong screen 'light-node' để kết nối với dashboard."
echo "Để thoát screen, nhấn CTRL+A rồi D."
