#!/bin/bash

# Định nghĩa màu sắc
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # Không màu

# Hiển thị banner và thông báo chào mừng
echo -e "${BLUE}"
echo -e "██████╗ ███████╗████████╗███████╗██████╗ ████████╗██████╗  █████╗ ███╗   ██╗"
echo -e "██╔══██╗██╔════╝╚══██╔══╝██╔════╝██╔══██╗╚══██╔══╝██╔══██╗██╔══██╗████╗  ██║"
echo -e "██████╔╝█████╗     ██║   █████╗  ██████╔╝   ██║   ██████╔╝███████║██╔██╗ ██║"
echo -e "██╔═══╝ ██╔══╝     ██║   ██╔══╝  ██╔══██╗   ██║   ██╔══██╗██╔══██║██║╚██╗██║"
echo -e "██║     ███████╗   ██║   ███████╗██║  ██║   ██║   ██║  ██║██║  ██║██║ ╚████║"
echo -e "╚═╝     ╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝"
echo -e "${NC}"
echo -e "${GREEN}Chào mừng bạn đến với LayerEdge Light Node!${NC}"
echo -e "Hướng dẫn này sẽ giúp bạn cài đặt và chạy node trên VPS một cách dễ dàng."
sleep 5

# 1️⃣ Thiết lập ban đầu
echo -e "${YELLOW}🚀 Bắt đầu quá trình cài đặt...${NC}"
echo -e "Cập nhật hệ thống và cài đặt các công cụ cơ bản..."
sudo apt update && sudo apt upgrade -y
sudo apt install build-essential git screen net-tools -y
echo -e "${GREEN}✅ Đã cập nhật hệ thống và cài đặt công cụ!${NC}"

# 2️⃣ Cài đặt Go 1.21.6
echo -e "${CYAN}📥 Cài đặt Go phiên bản 1.21.6...${NC}"
wget https://go.dev/dl/go1.21.6.linux-amd64.tar.gz -O go1.21.6.tar.gz
sudo tar -C /usr/local -xzf go1.21.6.tar.gz
echo "export GOROOT=/usr/local/go" >> ~/.bashrc
echo "export GOPATH=\$HOME/go" >> ~/.bashrc
echo "export PATH=\$GOPATH/bin:\$GOROOT/bin:\$PATH" >> ~/.bashrc
source ~/.bashrc
rm go1.21.6.tar.gz
go_version=$(go version)
echo -e "${GREEN}✅ Đã cài đặt $go_version!${NC}"

# 3️⃣ Cài đặt Rust và Cargo
echo -e "${CYAN}📥 Cài đặt Rust và Cargo...${NC}"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env
rustc_version=$(rustc --version)
echo -e "${GREEN}✅ Đã cài đặt Rust: $rustc_version!${NC}"
sudo apt install cargo -y

# 4️⃣ Cài đặt và kiểm tra Risc0 Toolchain
echo -e "${CYAN}📥 Cài đặt Risc0 Toolchain...${NC}"
curl -L https://risczero.com/install | bash
source "/root/.bashrc"
echo -e "Cài đặt Risc0 toolchain..."
rzup install
source "/root/.bashrc"
if command -v rzup >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Risc0 Toolchain đã được cài đặt!${NC}"
    rzup_version=$(rzup --version)
    echo -e "Phiên bản Risc0: $rzup_version"
else
    echo -e "${RED}❌ Không tìm thấy Risc0 Toolchain. Cài đặt lại...${NC}"
    curl -L https://risczero.com/install | bash
    rzup install
    source "/root/.bashrc"
    if ! command -v rzup >/dev/null 2>&1; then
        echo -e "${RED}❌ Lỗi cài đặt Risc0 Toolchain. Vui lòng kiểm tra kết nối mạng hoặc chạy thủ công.${NC}"
        exit 1
    fi
fi

# 5️⃣ Sao chép kho lưu trữ Light Node
echo -e "${YELLOW}🔗 Đang sao chép kho lưu trữ LayerEdge Light Node...${NC}"
rm -rf $HOME/light-node
git clone https://github.com/Layer-Edge/light-node.git $HOME/light-node
cd $HOME/light-node
echo -e "${GREEN}✅ Đã sao chép kho lưu trữ!${NC}"

# 6️⃣ Cấu hình tệp .env
echo -e "${YELLOW}🔄 Cấu hình biến môi trường...${NC}"
echo -e "${CYAN}🔑 Vui lòng nhập khóa riêng EVM của bạn (có thể dùng ví burner):${NC}"
read -p "Nhập khóa riêng: " PRIVATE_KEY
cat > .env << EOL
GRPC_URL=grpc.testnet.layeredge.io:9090
CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709
ZK_PROVER_URL=http://127.0.0.1:3001
API_REQUEST_TIMEOUT=100
POINTS_API=light-node.layeredge.io
PRIVATE_KEY=$PRIVATE_KEY
EOL
echo -e "${GREEN}✅ Đã tạo tệp .env với khóa riêng của bạn!${NC}"

# 7️⃣ Dọn dẹp các phiên screen cũ
echo -e "${YELLOW}🧹 Dọn dẹp các phiên screen cũ...${NC}"
screen -ls | grep Detached | awk '{print $1}' | xargs -I {} screen -X -S {} quit
echo -e "${GREEN}✅ Đã xóa các phiên screen cũ!${NC}"

# 8️⃣ Kiểm tra cổng 3001
echo -e "${YELLOW}🔍 Kiểm tra cổng 3001...${NC}"
if netstat -tuln | grep -q ":3001"; then
    echo -e "${RED}❌ Cổng 3001 đã bị chiếm dụng. Vui lòng dừng dịch vụ đang dùng cổng này.${NC}"
    exit 1
else
    echo -e "${GREEN}✅ Cổng 3001 trống, sẵn sàng chạy Risc0 Merkle Service!${NC}"
fi

# 9️⃣ Chạy Risc0 Merkle Service
echo -e "${YELLOW}🛠️ Biên dịch và chạy Risc0 Merkle Service...${NC}"
cd $HOME/light-node/risc0-merkle-service
cargo build
if [ $? -eq 0 ]; then
    screen -S layeredge -dm bash -c "cargo run > $HOME/risc0-merkle.log 2>&1"
    sleep 5
    if screen -ls | grep -q "layeredge"; then
        echo -e "${GREEN}🚀 Risc0 Merkle Service đang chạy trong phiên screen 'layeredge'!${NC}"
        echo -e "Log được lưu tại: ${CYAN}$HOME/risc0-merkle.log${NC}"
    else
        echo -e "${RED}❌ Risc0 Merkle Service không chạy. Kiểm tra log tại $HOME/risc0-merkle.log${NC}"
        cat $HOME/risc0-merkle.log
        exit 1
    fi
else
    echo -e "${RED}❌ Lỗi khi biên dịch Risc0 Merkle Service. Vui lòng kiểm tra log hoặc Rust/Risc0.${NC}"
    exit 1
fi

# 10️⃣ Biên dịch và chạy Light Node
echo -e "${YELLOW}🖥️ Biên dịch và chạy Light Node...${NC}"
cd $HOME/light-node
go build
if [ $? -eq 0 ]; then
    if [ -f ./light-node ]; then
        screen -S light-node -dm bash -c "./light-node > $HOME/light-node.log 2>&1"
        sleep 5
        if screen -ls | grep -q "light-node"; then
            echo -e "${GREEN}🚀 Light Node đang chạy trong phiên screen 'light-node'!${NC}"
            echo -e "Log được lưu tại: ${CYAN}$HOME/light-node.log${NC}"
        else
            echo -e "${RED}❌ Light Node không chạy. Kiểm tra log tại $HOME/light-node.log${NC}"
            cat $HOME/light-node.log
            exit 1
        fi
    else
        echo -e "${RED}❌ Không tìm thấy tệp thực thi 'light-node'. Vui lòng kiểm tra lại.${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ Lỗi khi biên dịch Light Node. Vui lòng kiểm tra Go và .env.${NC}"
    exit 1
fi

# 11️⃣ Kiểm tra trạng thái và hoàn tất
echo -e "${GREEN}🎉 Quá trình cài đặt hoàn tất!${NC}"
echo -e "Các dịch vụ đang chạy trong nền:"
echo -e "  - Risc0 Merkle Service: ${CYAN}screen -r layeredge${NC}"
echo -e "  - Light Node: ${CYAN}screen -r light-node${NC}"
echo -e "Để kiểm tra, dùng lệnh trên. Để dừng, vào screen và nhấn CTRL+C, rồi gõ 'exit'."
echo -e "${YELLOW}🔍 Kiểm tra danh sách screen:${NC}"
screen -ls
echo -e "${YELLOW}💡 Kiểm tra log nếu có lỗi:${NC}"
echo -e "  - Risc0 Merkle Service: ${CYAN}cat $HOME/risc0-merkle.log${NC}"
echo -e "  - Light Node: ${CYAN}cat $HOME/light-node.log${NC}"
