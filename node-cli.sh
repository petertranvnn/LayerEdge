#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Cập nhật hệ thống và cài công cụ cơ bản
echo -e "${YELLOW}🚀 Cập nhật hệ thống và cài công cụ cơ bản...${NC}"
apt update && apt upgrade -y || { echo -e "${RED}❌ Lỗi cập nhật hệ thống${NC}"; exit 1; }
apt install -y git curl screen build-essential || { echo -e "${RED}❌ Lỗi cài công cụ${NC}"; exit 1; }

# Cài Go
echo -e "${CYAN}📥 Cài đặt Go...${NC}"
wget https://go.dev/dl/go1.21.6.linux-amd64.tar.gz || { echo -e "${RED}❌ Lỗi tải Go${NC}"; exit 1; }
sudo tar -C /usr/local -xzf go1.21.6.linux-amd64.tar.gz
echo "export GOROOT=/usr/local/go" >> ~/.bashrc
echo "export GOPATH=\$HOME/go" >> ~/.bashrc
echo "export PATH=\$GOPATH/bin:\$GOROOT/bin:\$PATH" >> ~/.bashrc
source ~/.bashrc
go version && echo -e "${GREEN}✅ Đã cài Go: $(go version)${NC}"

# Cài Rust
echo -e "${CYAN}📥 Cài đặt Rust...${NC}"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y || { echo -e "${RED}❌ Lỗi cài Rust${NC}"; exit 1; }
source $HOME/.cargo/env
rustc --version && echo -e "${GREEN}✅ Đã cài Rust: $(rustc --version)${NC}"

# Cài Risc Zero
echo -e "${CYAN}📥 Cài đặt Risc Zero...${NC}"
curl -L https://risczero.com/install | bash || { echo -e "${RED}❌ Lỗi cài Risc Zero${NC}"; exit 1; }
export PATH="$PATH:/root/.risc0/bin"
echo "export PATH=\$PATH:/root/.risc0/bin" >> ~/.bashrc
source ~/.bashrc
rzup install || { echo -e "${RED}❌ Lỗi cài rzup${NC}"; exit 1; }
rzup --version && echo -e "${GREEN}✅ Đã cài Risc Zero: $(rzup --version)${NC}"

# Tải mã nguồn
echo -e "${YELLOW}🔗 Tải mã nguồn LayerEdge light-node...${NC}"
rm -rf $HOME/light-node
git clone https://github.com/Layer-Edge/light-node.git $HOME/light-node || { echo -e "${RED}❌ Lỗi tải mã nguồn${NC}"; exit 1; }
cd $HOME/light-node

# Tạo file .env
echo -e "${CYAN}🔄 Cấu hình biến môi trường...${NC}"
echo -e "${CYAN}🔧 Nhập GRPC_URL (Enter để dùng grpc.testnet.layeredge.io:9090):${NC}"
read -p "GRPC_URL: " GRPC_INPUT
if [ -z "$GRPC_INPUT" ]; then
    GRPC_URL="grpc.testnet.layeredge.io:9090"
else
    GRPC_URL="$GRPC_INPUT"
fi
cat << EOF > .env
GRPC_URL=$GRPC_URL
CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709
ZK_PROVER_URL=http://127.0.0.1:3001
API_REQUEST_TIMEOUT=120000
POINTS_API=light-node.layeredge.io
PRIVATE_KEY=
EOF
echo -e "${YELLOW}🔑 Nhập khóa riêng của bạn:${NC}"
read -p "Khóa riêng: " PRIVATE_KEY
echo "PRIVATE_KEY=$PRIVATE_KEY" >> .env
echo -e "${GREEN}✅ Đã tạo .env với GRPC_URL=$GRPC_URL${NC}"

# Kiểm tra kết nối gRPC
echo -e "${YELLOW}🔍 Kiểm tra kết nối gRPC...${NC}"
for i in {1..3}; do
    if nc -zv 34.31.74.109 9090 >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Kết nối $GRPC_URL thành công!${NC}"
        break
    else
        echo -e "${RED}❌ Lần thử $i: Không kết nối được $GRPC_URL${NC}"
        if [ $i -eq 3 ]; then
            echo -e "${RED}❌ Không thể kết nối sau 3 lần thử. Server có thể offline.${NC}"
            exit 1
        fi
        sleep 5
    fi
done

# Biên dịch và chạy risc0-merkle-service
echo -e "${YELLOW}🛠️ Biên dịch và chạy risc0-merkle-service...${NC}"
cd risc0-merkle-service
cargo build --release || { echo -e "${RED}❌ Lỗi biên dịch risc0-merkle-service${NC}"; exit 1; }
screen -dmS risc0-service cargo run --release || { echo -e "${RED}❌ Lỗi chạy risc0-service${NC}"; exit 1; }
echo -e "${GREEN}🚀 risc0-merkle-service đang chạy trong screen 'risc0-service'${NC}"

# Biên dịch và chạy light-node
echo -e "${YELLOW}🖥️ Biên dịch và chạy light-node...${NC}"
cd $HOME/light-node
go build || { echo -e "${RED}❌ Lỗi biên dịch light-node${NC}"; exit 1; }
screen -dmS light-node ./light-node || { echo -e "${RED}❌ Lỗi chạy light-node${NC}"; exit 1; }
echo -e "${GREEN}🚀 light-node đang chạy trong screen 'light-node'${NC}"

# Hoàn tất
echo -e "${GREEN}🎉 Cài đặt hoàn tất!${NC}"
echo -e "Kiểm tra dịch vụ: ${GREEN}screen -r risc0-service${NC} hoặc ${GREEN}screen -r light-node${NC}"
echo -e "Danh sách screen: ${GREEN}screen -ls${NC}"
