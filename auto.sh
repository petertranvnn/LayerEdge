#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m'

# Cài đặt các công cụ cơ bản
echo -e "${YELLOW}📦 Kiểm tra và cài đặt các công cụ cần thiết...${NC}"
for cmd in git curl screen gcc; do
    if ! command -v $cmd &> /dev/null; then
        echo -e "${YELLOW}Đang cài đặt $cmd...${NC}"
        sudo apt update && sudo apt install -y $cmd || { echo -e "${RED}❌ Cài đặt $cmd thất bại!${NC}"; exit 1; }
    fi
done

# Cài đặt Rust và Cargo nếu chưa có
if ! command -v cargo &> /dev/null; then
    echo -e "${YELLOW}📦 Cài đặt Rust và Cargo...${NC}"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi
source "$HOME/.cargo/env"  # Cập nhật PATH ngay lập tức

echo -e "${CYAN}   ____ ______   _______ ______   _    _ ${NC}"
echo -e "${CYAN}  / __ \  __ \ \ / /_   _|  _ \ | |  | |${NC}"
echo -e "${YELLOW} | |  | | |__) \ V /  | | | |_) || |__| |${NC}"
echo -e "${YELLOW} | |__| |  ___/ > <   | | |  _ < |  __  |${NC}"
echo -e "${CYAN}  \____/|_|    /_/\_| |_| |_| \_|_|  |_|${NC}"
echo -e "Welcome to PETERTRAN! Join Telegram: https://t.me/NTExhaust"
sleep 5

echo -e "🚀 Bắt đầu quá trình cài đặt..."
rm -rf $HOME/light-node
echo -e "🔗 Đang sao chép kho lưu trữ..."
git clone https://github.com/Layer-Edge/light-node.git && echo -e "✅ Đã sao chép kho lưu trữ!" || { echo -e "${RED}❌ Clone thất bại!${NC}"; exit 1; }
cd light-node

echo -e "📥 Đang tải và cài đặt các phụ thuộc..."
curl -L https://risczero.com/install | bash && echo -e "✅ Đã cài đặt phụ thuộc Risc Zero!" || { echo -e "${RED}❌ Cài đặt Risc Zero thất bại!${NC}"; exit 1; }
source "/root/.bashrc"  # Cập nhật môi trường

echo -e "🔄 Đang áp dụng các biến môi trường..."
export GRPC_URL=34.31.74.109:9090
export CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709
export ZK_PROVER_URL=http://127.0.0.1:3001
export API_REQUEST_TIMEOUT=100
export POINTS_API=http://127.0.0.1:8080
echo -e "🔑 Vui lòng nhập khóa riêng của bạn: "
read -s PRIVATE_KEY
echo "export PRIVATE_KEY=$PRIVATE_KEY" >> $HOME/.lightnode_config
source $HOME/.lightnode_config
echo -e "✅ Đã thiết lập khóa riêng!"

echo -e "🛠️ Đang xây dựng và chạy risc0-merkle-service..."
cd risc0-merkle-service
cargo build && screen -dmS risc0-service cargo run && echo -e "🚀 risc0-merkle-service đang chạy!" || { echo -e "${RED}❌ Build risc0-merkle-service thất bại!${NC}"; exit 1; }

echo -e "🖥️ Đang khởi động máy chủ light-node..."
cd .. && screen -dmS light-node ./target/debug/light-node && echo -e "✅ Light node đã khởi động!" || { echo -e "${RED}❌ Khởi động light-node thất bại!${NC}"; exit 1; }

echo -e "🎉 Hoàn tất cài đặt! Cả hai máy chủ đang chạy trong các phiên screen!"
echo -e "${GREEN}Kiểm tra: screen -ls${NC}"
