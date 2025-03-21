#!/bin/bash

# Màu sắc cho giao diện
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m'

# Tệp log
LOG_FILE="$HOME/light_node_setup.log"
echo "Quá trình cài đặt bắt đầu lúc $(date)" > "$LOG_FILE"

# Kiểm tra kết nối internet
echo -e "${CYAN}🔍 Kiểm tra kết nối internet...${NC}"
if ! ping -c 3 google.com &> /dev/null; then
    echo -e "${RED}❌ Không phát hiện kết nối internet! Vui lòng kiểm tra mạng.${NC}" | tee -a "$LOG_FILE"
    exit 1
fi
echo -e "${GREEN}✅ Kết nối internet hoạt động!${NC}" | tee -a "$LOG_FILE"

# logo
echo -e '\e[34m'
echo -e "██████╗ ███████╗████████╗███████╗██████╗ ████████╗██████╗  █████╗ ███╗   ██╗"
echo -e "██╔══██╗██╔════╝╚══██╔══╝██╔════╝██╔══██╗╚══██╔══╝██╔══██╗██╔══██╗████╗  ██║"
echo -e "██████╔╝█████╗     ██║   █████╗  ██████╔╝   ██║   ██████╔╝███████║██╔██╗ ██║"
echo -e "██╔═══╝ ██╔══╝     ██║   ██╔══╝  ██╔══██╗   ██║   ██╔══██╗██╔══██║██║╚██╗██║"
echo -e "██║     ███████╗   ██║   ███████╗██║  ██║   ██║   ██║  ██║██║  ██║██║ ╚████║"
echo -e "╚═╝     ╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝"
echo -e '\e[0m'
echo -e "Chào mừng bạn đến với chương trình lên đỉnh Node/validator" | tee -a "$LOG_FILE"

# Bắt đầu quá trình cài đặt
echo -e "${YELLOW}🚀 Bắt đầu quá trình cài đặt...${NC}" | tee -a "$LOG_FILE"

# Cập nhật hệ thống và cài đặt các công cụ cần thiết
echo -e "${CYAN}🔄 Cập nhật hệ thống và cài đặt các công cụ...${NC}" | tee -a "$LOG_FILE"
sudo apt update && sudo apt upgrade -y >> "$LOG_FILE" 2>&1
sudo apt install -y git curl build-essential screen ufw >> "$LOG_FILE" 2>&1

# Cấu hình tường lửa
echo -e "${CYAN}🔒 Cấu hình tường lửa...${NC}" | tee -a "$LOG_FILE"
sudo ufw allow 22   # SSH
sudo ufw allow 9090 # gRPC
sudo ufw allow 3001 # ZK Prover
sudo ufw enable -y >> "$LOG_FILE" 2>&1
echo -e "${GREEN}✅ Tường lửa đã được kích hoạt!${NC}" | tee -a "$LOG_FILE"

# Kiểm tra và cài đặt Go
if ! command -v go &> /dev/null || [[ $(go version | awk '{print $3}' | sed 's/go//') < "1.18" ]]; then
    echo -e "${CYAN}📦 Cài đặt Go...${NC}" | tee -a "$LOG_FILE"
    wget https://go.dev/dl/go1.21.8.linux-amd64.tar.gz -O go.tar.gz >> "$LOG_FILE" 2>&1
    sudo tar -C /usr/local -xzf go.tar.gz >> "$LOG_FILE" 2>&1
    echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee -a /etc/profile > /dev/null
    source /etc/profile
    rm go.tar.gz
    if command -v go &> /dev/null; then
        echo -e "${GREEN}✅ Đã cài đặt Go: $(go version)${NC}" | tee -a "$LOG_FILE"
    else
        echo -e "${RED}❌ Lỗi: Không thể cài đặt Go!${NC}" | tee -a "$LOG_FILE"
        exit 1
    fi
else
    echo -e "${GREEN}✅ Go đã được cài đặt: $(go version)${NC}" | tee -a "$LOG_FILE"
fi

# Kiểm tra và cài đặt Rust
if ! command -v rustc &> /dev/null || [[ $(rustc --version | awk '{print $2}') < "1.81.0" ]]; then
    echo -e "${CYAN}📦 Cài đặt Rust...${NC}" | tee -a "$LOG_FILE"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y >> "$LOG_FILE" 2>&1
    source "$HOME/.cargo/env"
    rustup update >> "$LOG_FILE" 2>&1
    echo -e "${GREEN}✅ Đã cài đặt Rust: $(rustc --version)${NC}" | tee -a "$LOG_FILE"
else
    echo -e "${GREEN}✅ Rust đã được cài đặt: $(rustc --version)${NC}" | tee -a "$LOG_FILE"
fi

# Cài đặt Risc0 Toolchain
echo -e "${CYAN}📥 Cài đặt Risc0 Toolchain...${NC}" | tee -a "$LOG_FILE"
curl -L https://risczero.com/install | bash >> "$LOG_FILE" 2>&1
rzup install >> "$LOG_FILE" 2>&1
source "$HOME/.bashrc"
echo -e "${GREEN}✅ Đã cài đặt Risc0 Toolchain!${NC}" | tee -a "$LOG_FILE"

# Sao chép kho lưu trữ
echo -e "${YELLOW}🗑️ Xóa thư mục light-node cũ nếu tồn tại...${NC}" | tee -a "$LOG_FILE"
rm -rf "$HOME/light-node"
echo -e "${CYAN}🔗 Sao chép kho lưu trữ...${NC}" | tee -a "$LOG_FILE"
git clone https://github.com/Layer-Edge/light-node.git >> "$LOG_FILE" 2>&1 && echo -e "${GREEN}✅ Đã sao chép kho lưu trữ!${NC}" | tee -a "$LOG_FILE"
cd light-node || exit

# Yêu cầu người dùng nhập Private Key
while true; do
    echo -e "${YELLOW}🔑 Vui lòng nhập Private Key của bạn: ${NC}"
    read -r PRIVATE_KEY
    if [ -z "$PRIVATE_KEY" ]; then
        echo -e "${RED}❌ Lỗi: Private Key không được để trống! Vui lòng nhập lại.${NC}" | tee -a "$LOG_FILE"
    else
        echo -e "${GREEN}✅ Đã nhận Private Key thành công!${NC}" | tee -a "$LOG_FILE"
        break
    fi
done
export PRIVATE_KEY

# Thiết lập biến môi trường
echo -e "${CYAN}🔄 Thiết lập biến môi trường...${NC}" | tee -a "$LOG_FILE"
export GRPC_URL="grpc.testnet.layeredge.io:9090"
export CONTRACT_ADDR="cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709"
export ZK_PROVER_URL="http://127.0.0.1:3001"
export API_REQUEST_TIMEOUT=100
export POINTS_API="https://light-node.layeredge.io"

# Lưu biến môi trường vào .env
echo "GRPC_URL=$GRPC_URL" > .env
echo "CONTRACT_ADDR=$CONTRACT_ADDR" >> .env
echo "ZK_PROVER_URL=$ZK_PROVER_URL" >> .env
echo "API_REQUEST_TIMEOUT=$API_REQUEST_TIMEOUT" >> .env
echo "POINTS_API=$POINTS_API" >> .env
echo "PRIVATE_KEY=$PRIVATE_KEY" >> .env
chmod 600 .env  # Bảo mật tệp .env

# Khởi động dịch vụ Merkle
echo -e "${YELLOW}🛠️ Xây dựng và chạy risc0-merkle-service...${NC}" | tee -a "$LOG_FILE"
cd risc0-merkle-service || exit
cargo build >> "$LOG_FILE" 2>&1 && screen -dmS risc0-service cargo run && echo -e "${GREEN}🚀 risc0-merkle-service đang chạy trong phiên screen!${NC}" | tee -a "$LOG_FILE"
for i in {1..30}; do
    if screen -list | grep -q "risc0-service"; then
        echo -e "${GREEN}✅ risc0-merkle-service đã khởi động thành công!${NC}" | tee -a "$LOG_FILE"
        break
    fi
    sleep 1
done

# Chạy Light Node
cd .. || exit
echo -e "${YELLOW}🖥️ Khởi động máy chủ light-node...${NC}" | tee -a "$LOG_FILE"
go build >> "$LOG_FILE" 2>&1 && screen -dmS light-node ./light-node && echo -e "${GREEN}🚀 light-node đang chạy trong phiên screen!${NC}" | tee -a "$LOG_FILE"

# Tự động lấy điểm từ API
echo -e "${CYAN}📊 Kết nối CLI Node với LayerEdge Dashboard...${NC}" | tee -a "$LOG_FILE"
WALLET_ADDRESS="$CONTRACT_ADDR"  # Giả sử ví CLI là CONTRACT_ADDR
POINTS_URL="https://light-node.layeredge.io/api/cli-node/points/$WALLET_ADDRESS"
curl -s "$POINTS_URL" >> "$LOG_FILE" 2>&1 && echo -e "${GREEN}✅ Đã lấy điểm từ API: $POINTS_URL${NC}" | tee -a "$LOG_FILE"

# Hoàn tất
echo -e "${GREEN}🎉 Hoàn tất cài đặt!${NC}" | tee -a "$LOG_FILE"
echo -e "${CYAN}ℹ️ Kiểm tra dịch vụ: 'screen -r risc0-service' hoặc 'screen -r light-node'${NC}" | tee -a "$LOG_FILE"
echo -e "${CYAN}ℹ️ Log chi tiết tại: $LOG_FILE${NC}" | tee -a "$LOG_FILE"
echo -e "${CYAN}ℹ️ Kết nối ví tại: dashboard.layeredge.io${NC}" | tee -a "$LOG_FILE"
