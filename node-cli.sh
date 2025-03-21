#!/bin/bash

# Định nghĩa màu sắc
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # Không màu

# Hiển thị banner
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

# 1️⃣ Thiết lập ban đầu
echo -e "${YELLOW}🚀 Bắt đầu cài đặt...${NC}"
sudo apt update && sudo apt upgrade -y
sudo apt install build-essential git screen net-tools curl telnet -y
echo -e "${GREEN}✅ Đã cài công cụ cơ bản!${NC}"

# 2️⃣ Cài đặt Go 1.21.6
echo -e "${CYAN}📥 Cài đặt Go 1.21.6...${NC}"
wget https://go.dev/dl/go1.21.6.linux-amd64.tar.gz -O go1.21.6.tar.gz
sudo tar -C /usr/local -xzf go1.21.6.tar.gz
echo "export GOROOT=/usr/local/go" >> ~/.bashrc
echo "export GOPATH=\$HOME/go" >> ~/.bashrc
echo "export PATH=\$GOPATH/bin:\$GOROOT/bin:\$PATH" >> ~/.bashrc
source ~/.bashrc
rm go1.21.6.tar.gz
echo -e "${GREEN}✅ Đã cài $(go version)!${NC}"

# 3️⃣ Cài đặt Rust và Cargo
echo -e "${CYAN}📥 Cài đặt Rust và Cargo...${NC}"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env
sudo apt install cargo -y
echo -e "${GREEN}✅ Đã cài Rust: $(rustc --version)!${NC}"

# 4️⃣ Cài đặt Risc0 Toolchain
echo -e "${CYAN}📥 Cài đặt Risc0 Toolchain...${NC}"
curl -L https://risczero.com/install | bash
source "/root/.bashrc"
rzup install
source "/root/.bashrc"
if command -v rzup >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Risc0 Toolchain: $(rzup --version)!${NC}"
else
    echo -e "${RED}❌ Không cài được Risc0 Toolchain. Thoát...${NC}"
    exit 1
fi

# 5️⃣ Sao chép kho lưu trữ
echo -e "${YELLOW}🔗 Sao chép kho lưu trữ...${NC}"
rm -rf $HOME/light-node
git clone https://github.com/Layer-Edge/light-node.git $HOME/light-node
cd $HOME/light-node
echo -e "${GREEN}✅ Đã sao chép!${NC}"

# 6️⃣ Cấu hình .env
echo -e "${YELLOW}🔄 Cấu hình .env...${NC}"
echo -e "${CYAN}🔑 Nhập khóa riêng EVM (có thể dùng ví burner):${NC}"
read -p "Nhập khóa riêng: " PRIVATE_KEY
echo -e "${CYAN}🔧 Chọn ZK_PROVER_URL: ${NC}"
echo -e "  1. http://127.0.0.1:3001 (chạy cục bộ - yêu cầu Risc0 Merkle Service)"
echo -e "  2. layeredge.mintair.xyz (dùng server bên ngoài)"
read -p "Nhập lựa chọn (1 hoặc 2): " ZK_CHOICE
if [ "$ZK_CHOICE" == "1" ]; then
    ZK_PROVER_URL="http://127.0.0.1:3001"
    RUN_LOCAL_ZK=1
elif [ "$ZK_CHOICE" == "2" ]; then
    ZK_PROVER_URL="layeredge.mintair.xyz"
    RUN_LOCAL_ZK=0
else
    echo -e "${RED}❌ Lựa chọn không hợp lệ. Thoát...${NC}"
    exit 1
fi

cat > .env << EOL
GRPC_URL=grpc.testnet.layeredge.io:9090
CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709
ZK_PROVER_URL=$ZK_PROVER_URL
API_REQUEST_TIMEOUT=120000  # 120 giây timeout
POINTS_API=light-node.layeredge.io
PRIVATE_KEY=$PRIVATE_KEY
EOL
echo -e "${GREEN}✅ Đã tạo .env với ZK_PROVER_URL=$ZK_PROVER_URL!${NC}"

# 7️⃣ Kiểm tra tài nguyên và mạng
echo -e "${YELLOW}🔍 Kiểm tra tài nguyên...${NC}"
cpu_cores=$(nproc)
memory=$(free -h | awk '/^Mem:/ {print $2}')
echo -e "CPU: $cpu_cores cores"
echo -e "RAM: $memory"
if [ $cpu_cores -lt 2 ] || [ $(free -m | awk '/^Mem:/ {print $2}') -lt 2048 ]; then
    echo -e "${YELLOW}⚠️ VPS có thể không đủ mạnh.${NC}"
fi

echo -e "${YELLOW}🔍 Kiểm tra kết nối gRPC...${NC}"
attempts=0
max_attempts=3
while [ $attempts -lt $max_attempts ]; do
    nc -zv 34.31.74.109 9090 > /tmp/grpc_check 2>&1
    if grep -q "succeeded" /tmp/grpc_check; then
        echo -e "${GREEN}✅ Kết nối grpc.testnet.layeredge.io:9090 OK!${NC}"
        rm /tmp/grpc_check
        break
    else
        error=$(cat /tmp/grpc_check)
        echo -e "${RED}❌ Lần thử $((attempts + 1)): Không kết nối được grpc.testnet.layeredge.io:9090. Lỗi: $error${NC}"
        attempts=$((attempts + 1))
        sleep 5
    fi
done
if [ $attempts -eq $max_attempts ]; then
    echo -e "${RED}❌ Không thể kết nối sau $max_attempts lần thử.${NC}"
    echo -e "${YELLOW}Kiểm tra thủ công:${NC}"
    echo -e "  - nc -zv 34.31.74.109 9090"
    echo -e "  - telnet 34.31.74.109 9090"
    echo -e "  - ping grpc.testnet.layeredge.io"
    echo -e "${YELLOW}Server testnet có thể offline. Liên hệ LayerEdge qua Telegram: https://t.me/NTExhaust${NC}"
    rm /tmp/grpc_check
    exit 1
fi

# 8️⃣ Dọn dẹp screen cũ
echo -e "${YELLOW}🧹 Dọn dẹp screen cũ...${NC}"
screen -ls | grep Detached | awk '{print $1}' | xargs -I {} screen -X -S {} quit
echo -e "${GREEN}✅ Đã xóa screen cũ!${NC}"

# 9️⃣ Chạy Risc0 Merkle Service (nếu chọn cục bộ)
if [ "$RUN_LOCAL_ZK" -eq 1 ]; then
    echo -e "${YELLOW}🛠️ Biên dịch Risc0 Merkle Service...${NC}"
    cd $HOME/light-node/risc0-merkle-service
    cargo build --release
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Lỗi biên dịch Risc0 Merkle Service.${NC}"
        exit 1
    fi

    echo -e "${YELLOW}🚀 Khởi động Risc0 Merkle Service...${NC}"
    attempts=0
    max_attempts=3
    while [ $attempts -lt $max_attempts ]; do
        if netstat -tuln | grep -q ":3001"; then
            echo -e "${YELLOW}🔍 Cổng 3001 đang bị chiếm. Đóng tiến trình cũ...${NC}"
            kill $(lsof -t -i:3001)
        fi
        screen -S layeredge -dm bash -c "cargo run --release > $HOME/risc0-merkle.log 2>&1"
        sleep 60
        if screen -ls | grep -q "layeredge" && curl -s http://127.0.0.1:3001 >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Risc0 Merkle Service đang chạy trên cổng 3001!${NC}"
            echo -e "Log: ${CYAN}$HOME/risc0-merkle.log${NC}"
            break
        else
            echo -e "${RED}❌ Lần thử $((attempts + 1)) thất bại:${NC}"
            cat $HOME/risc0-merkle.log
            attempts=$((attempts + 1))
            sleep 5
        fi
    done
    if [ $attempts -eq $max_attempts ]; then
        echo -e "${RED}❌ Không thể chạy Risc0 Merkle Service:${NC}"
        cat $HOME/risc0-merkle.log
        exit 1
    fi
else
    echo -e "${YELLOW}🔧 Dùng ZK_PROVER_URL bên ngoài: $ZK_PROVER_URL. Bỏ qua chạy cục bộ.${NC}"
fi

# 10️⃣ Biên dịch và chạy Light Node
echo -e "${YELLOW}🖥️ Biên dịch và chạy Light Node...${NC}"
cd $HOME/light-node
go build
if [ $? -eq 0 ] && [ -f ./light-node ]; then
    screen -S light-node -dm bash -c "./light-node > $HOME/light-node.log 2>&1"
    sleep 120
    if screen -ls | grep -q "light-node"; then
        echo -e "${GREEN}✅ Light Node đang chạy!${NC}"
        echo -e "Log: ${CYAN}$HOME/light-node.log${NC}"
    else
        echo -e "${RED}❌ Light Node thất bại:${NC}"
        cat $HOME/light-node.log
        exit 1
    fi
else
    echo -e "${RED}❌ Lỗi biên dịch Light Node.${NC}"
    exit 1
fi

# 11️⃣ Hoàn tất
echo -e "${GREEN}🎉 Cài đặt hoàn tất!${NC}"
echo -e "Dịch vụ đang chạy:"
if [ "$RUN_LOCAL_ZK" -eq 1 ]; then
    echo -e "  - Risc0 Merkle Service: ${CYAN}screen -r layeredge${NC}"
fi
echo -e "  - Light Node: ${CYAN}screen -r light-node${NC}"
echo -e "${YELLOW}🔍 Danh sách screen:${NC}"
screen -ls
echo -e "${YELLOW}💡 Kiểm tra log:${NC}"
if [ "$RUN_LOCAL_ZK" -eq 1 ]; then
    echo -e "  - Risc0: ${CYAN}cat $HOME/risc0-merkle.log${NC}"
fi
echo -e "  - Light Node: ${CYAN}cat $HOME/light-node.log${NC}"
