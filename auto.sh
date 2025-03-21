# Màu sắc cho giao diện
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m'

# Hiển thị
echo -e '\e[34m'
echo -e "██████╗ ███████╗████████╗███████╗██████╗ ████████╗██████╗  █████╗ ███╗   ██╗"
echo -e "██╔══██╗██╔════╝╚══██╔══╝██╔════╝██╔══██╗╚══██╔══╝██╔══██╗██╔══██╗████╗  ██║"
echo -e "██████╔╝█████╗     ██║   █████╗  ██████╔╝   ██║   ██████╔╝███████║██╔██╗ ██║"
echo -e "██╔═══╝ ██╔══╝     ██║   ██╔══╝  ██╔══██╗   ██║   ██╔══██╗██╔══██║██║╚██╗██║"
echo -e "██║     ███████╗   ██║   ███████╗██║  ██║   ██║   ██║  ██║██║  ██║██║ ╚████║"
echo -e "╚═╝     ╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝"
echo -e '\e[0m'
echo -e "Welcome to the setup script by PETERTRAN"
sleep 5

# Bắt đầu quá trình cài đặt
echo -e "${YELLOW}🚀 Starting setup process...${NC}"

# Cập nhật hệ thống và cài đặt các công cụ cần thiết
echo -e "${CYAN}🔄 Updating system and installing prerequisites...${NC}"
sudo apt update && sudo apt upgrade -y
sudo apt install -y git curl build-essential screen

# Kiểm tra và cài đặt Go nếu chưa có (yêu cầu phiên bản 1.18 trở lên)
if ! command -v go &> /dev/null || [[ $(go version | awk '{print $3}' | sed 's/go//') < "1.18" ]]; then
    echo -e "${CYAN}📦 Installing Go...${NC}"
    wget https://go.dev/dl/go1.21.8.linux-amd64.tar.gz
    sudo tar -C /usr/local -xzf go1.21.8.linux-amd64.tar.gz
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    source ~/.bashrc
    rm go1.21.8.linux-amd64.tar.gz
    echo -e "${GREEN}✅ Go installed: $(go version)${NC}"
else
    echo -e "${GREEN}✅ Go is already installed: $(go version)${NC}"
fi

# Kiểm tra và cài đặt Rust nếu chưa có (yêu cầu phiên bản 1.81.0 trở lên)
if ! command -v rustc &> /dev/null || [[ $(rustc --version | awk '{print $2}') < "1.81.0" ]]; then
    echo -e "${CYAN}📦 Installing Rust...${NC}"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
    rustup update
    echo -e "${GREEN}✅ Rust installed: $(rustc --version)${NC}"
else
    echo -e "${GREEN}✅ Rust is already installed: $(rustc --version)${NC}"
fi

# Cài đặt Risc0 Toolchain
echo -e "${CYAN}📥 Installing Risc0 Toolchain...${NC}"
curl -L https://risczero.com/install | bash
rzup install
source "$HOME/.bashrc"
echo -e "${GREEN}✅ Risc0 Toolchain installed!${NC}"

# Xóa thư mục cũ nếu tồn tại và sao chép kho lưu trữ
echo -e "${YELLOW}🗑️ Removing old light-node directory if exists...${NC}"
rm -rf "$HOME/light-node"
echo -e "${CYAN}🔗 Cloning repository...${NC}"
git clone https://github.com/Layer-Edge/light-node.git && echo -e "${GREEN}✅ Repository cloned!${NC}"
cd light-node || exit

# Thiết lập biến môi trường
echo -e "${CYAN}🔄 Applying environment variables...${NC}"
export GRPC_URL="grpc.testnet.layeredge.io:9090"
export CONTRACT_ADDR="cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709"
export ZK_PROVER_URL="http://127.0.0.1:3001"
export API_REQUEST_TIMEOUT=100
export POINTS_API="https://light-node.layeredge.io"

# Yêu cầu người dùng nhập khóa riêng
echo -e "${YELLOW}🔑 Please enter your private key: ${NC}"
read -r PRIVATE_KEY
if [ -z "$PRIVATE_KEY" ]; then
    echo -e "${RED}❌ Error: Private key cannot be empty!${NC}"
    exit 1
fi
export PRIVATE_KEY
echo -e "${GREEN}✅ Private key set!${NC}"

# Lưu biến môi trường vào file .env để sử dụng lâu dài
echo "GRPC_URL=$GRPC_URL" > .env
echo "CONTRACT_ADDR=$CONTRACT_ADDR" >> .env
echo "ZK_PROVER_URL=$ZK_PROVER_URL" >> .env
echo "API_REQUEST_TIMEOUT=$API_REQUEST_TIMEOUT" >> .env
echo "POINTS_API=$POINTS_API" >> .env
echo "PRIVATE_KEY=$PRIVATE_KEY" >> .env

# Xây dựng và chạy dịch vụ Merkle
echo -e "${YELLOW}🛠️ Building and running risc0-merkle-service...${NC}"
cd risc0-merkle-service || exit
cargo build && screen -dmS risc0-service cargo run && echo -e "${GREEN}🚀 risc0-merkle-service is running in a screen session!${NC}"
sleep 5 # Đợi dịch vụ khởi động

# Quay lại thư mục gốc và chạy Light Node
cd .. || exit
echo -e "${YELLOW}🖥️ Starting light-node server in a screen session...${NC}"
go build && screen -dmS light-node ./light-node && echo -e "${GREEN}🚀 light-node is running in a screen session!${NC}"

# Hoàn tất
echo -e "${GREEN}🎉 Setup complete! Both servers are running independently in screen sessions!${NC}"
echo -e "${CYAN}ℹ️ Use 'screen -r risc0-service' or 'screen -r light-node' to check the running services.${NC}"
