#!/bin/bash

RED='\033[0;31m'    # Màu đỏ
GREEN='\033[0;32m'  # Màu xanh lá
YELLOW='\033[1;33m' # Màu vàng đậm
BLUE='\033[0;34m'   # Màu xanh dương
NC='\033[0m'        # Không màu (reset)

cat << "EOF"
${RED}
  PPPPP   EEEEE  TTTTT  EEEEE  RRRR      TTTTT  RRRR   AAA   NNNN  
${GREEN}  P    P  E        T    E      R    R      T    R    R A   A  N   N 
${YELLOW}  PPPPP   EEEE     T    EEEE   RRRR       T    RRRR   AAAAA  N   N 
${BLUE}  P       E        T    E      R  R       T    R  R   A   A  N   N 
${RED}  P       EEEEE    T    EEEEE  R   R      T    R   R  A   A  NNNN  
${NC}
  LayerEdge Light Node Setup by Peter Tran
EOF

echo "Chào mừng bạn đến với chương trình lên đỉnh node/validator!"
echo "Script này được viết bởi Peter Tran - Bắt đầu cài đặt nào..."
sleep 2

# Bước 1: Kiểm tra và giải phóng khóa apt
echo "Kiểm tra khóa apt..."
if [ -f /var/lib/dpkg/lock-frontend ]; then
    echo "Phát hiện khóa apt. Đang giải phóng..."
    sudo fuser /var/lib/dpkg/lock-frontend
    sudo rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock
    sudo dpkg --configure -a
    echo "Đã giải phóng khóa!"
fi

# Bước 2: Cập nhật hệ thống và cài đặt gói cần thiết
echo "Cập nhật hệ thống và cài đặt gói phụ thuộc..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl git build-essential pkg-config libssl-dev

# Bước 3: Cài đặt Go (phiên bản 1.18 trở lên, dùng 1.21.8 cho mới nhất)
echo "Cài đặt Go..."
wget -q https://go.dev/dl/go1.21.8.linux-amd64.tar.gz || { echo "Lỗi tải Go! Kiểm tra kết nối mạng."; exit 1; }
sudo tar -C /usr/local -xzf go1.21.8.linux-amd64.tar.gz
echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.bashrc
source ~/.bashrc

# Bước 4: Cài đặt Rust (phiên bản 1.81.0 trở lên) và Risc0 Toolchain
echo "Cài đặt Rust và Risc0 Toolchain..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env
rustup update
rustup install 1.81.0
rustup default 1.81.0
curl -L https://risczero.com/install | bash && rzup install

# Bước 5: Sao chép kho lưu trữ Light Node
echo "Sao chép mã nguồn LayerEdge Light Node..."
git clone https://github.com/Layer-Edge/light-node.git || { echo "Lỗi tải mã nguồn! Kiểm tra kết nối mạng."; exit 1; }
cd light-node

# Bước 6: Yêu cầu nhập Private Key một cách an toàn
echo "Vui lòng nhập Private Key của bạn (ký tự sẽ không hiển thị):"
read -s PRIVATE_KEY
if [ -z "$PRIVATE_KEY" ]; then
    echo "Lỗi: Private Key không được để trống. Script sẽ thoát."
    exit 1
fi

# Bước 7: Tạo file .env với cấu hình biến môi trường
echo "Tạo file cấu hình .env..."
cat <<EOF > .env
GRPC_URL=grpc.testnet.layeredge.io:9090
CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709
ZK_PROVER_URL=https://layeredge.mintair.xyz/
API_REQUEST_TIMEOUT=100
POINTS_API=https://light-node.layeredge.io
PRIVATE_KEY=$PRIVATE_KEY
EOF

# Bước 8: Khởi động dịch vụ Merkle trong background
echo "Khởi động dịch vụ Merkle..."
cd risc0-merkle-service
cargo build || { echo "Lỗi biên dịch dịch vụ Merkle!"; exit 1; }
cargo run & # Chạy nền để tiếp tục script
MERKLE_PID=$! # Lưu PID để quản lý
echo "Dịch vụ Merkle đang chạy với PID $MERKLE_PID. Đợi khởi tạo..."
sleep 10 # Chờ 10 giây để dịch vụ khởi tạo

# Bước 9: Xây dựng và chạy Light Node
cd ..
echo "Biên dịch và chạy LayerEdge Light Node..."
go build -o light-node || { echo "Lỗi biên dịch Light Node!"; exit 1; }

# Cấu hình systemd để chạy Light Node
sudo bash -c "cat <<EOF > /etc/systemd/system/layeredge.service
[Unit]
Description=LayerEdge CLI Light Node bởi Peter Tran
After=network.target

[Service]
ExecStart=$(pwd)/light-node
WorkingDirectory=$(pwd)
Restart=always
User=$(whoami)
EnvironmentFile=$(pwd)/.env

[Install]
WantedBy=multi-user.target
EOF"

# Khởi động dịch vụ
echo "Khởi động node LayerEdge..."
sudo systemctl daemon-reload
sudo systemctl enable layeredge.service
sudo systemctl start layeredge.service

# Thông báo hoàn tất
echo -e "${GREEN}LayerEdge CLI Light Node đã được cài đặt và khởi động thành công!${NC}"
echo "Kiểm tra trạng thái: sudo systemctl status layeredge.service"
echo "Xem log: journalctl -u layeredge.service -f"
echo -e "${YELLOW}Cảm ơn bạn đã sử dụng script của Peter Tran!${NC}"
