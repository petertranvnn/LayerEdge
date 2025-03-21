#!/bin/bash

cat << "EOF"

  PPPPP   EEEEE  TTTTT  EEEEE  RRRR      TTTTT  RRRR   AAA   NNNN  
  P    P  E        T    E      R    R      T    R    R A   A  N   N 
  PPPPP   EEEE     T    EEEE   RRRR       T    RRRR   AAAAA  N   N 
  P       E        T    E      R  R       T    R  R   A   A  N   N 
  P       EEEEE    T    EEEEE  R   R      T    R   R  A   A  NNNN  

  LayerEdge Node Setup by Peter Tran
EOF

echo "Chào mừng bạn đến với hội đu node!"
echo "Script này được viết bởi Peter Tran - Bắt đầu cài đặt nào..."
sleep 2

# Bước 1: Kiểm tra và giải phóng khóa apt nếu bị giữ
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

# Bước 3: Cài đặt Go (phiên bản 1.21.8)
echo "Cài đặt Go..."
wget -q https://go.dev/dl/go1.21.8.linux-amd64.tar.gz || { echo "Lỗi tải Go! Kiểm tra kết nối mạng."; exit 1; }
sudo tar -C /usr/local -xzf go1.21.8.linux-amd64.tar.gz
echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.bashrc
source ~/.bashrc

# Bước 4: Cài đặt Rust và Risc0 cho Zero-Knowledge proofs
echo "Cài đặt Rust và Risc0..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env
cargo install cargo-risczero
risczero install

# Bước 5: Tải mã nguồn LayerEdge
echo "Tải mã nguồn LayerEdge..."
git clone https://github.com/Layer-Edge/light-node.git || { echo "Lỗi tải mã nguồn! Kiểm tra kết nối mạng."; exit 1; }
cd light-node

# Bước 6: Yêu cầu nhập Private Key một cách an toàn
echo "Peter Tran, vui lòng nhập Private Key của bạn (ký tự sẽ không hiển thị):"
read -s PRIVATE_KEY
if [ -z "$PRIVATE_KEY" ]; then
    echo "Lỗi: Peter Tran, Private Key không được để trống. Script sẽ thoát."
    exit 1
fi

# Bước 7: Tạo file .env với Private Key vừa nhập
echo "Tạo file cấu hình .env..."
cat <<EOF > .env
GRPC_URL=34.31.74.109:9090
CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709
ZK_PROVER_URL=https://layeredge.mintair.xyz/
API_REQUEST_TIMEOUT=100
POINTS_API=https://light-node.layeredge.io
PRIVATE_KEY=$PRIVATE_KEY
EOF

# Bước 8: Biên dịch LayerEdge CLI
echo "Biên dịch LayerEdge CLI..."
go build -o layeredge-cli main.go || { echo "Lỗi biên dịch! Kiểm tra Go và mã nguồn."; exit 1; }

# Bước 9: Cấu hình dịch vụ systemd
echo "Cấu hình dịch vụ chạy nền..."
sudo bash -c "cat <<EOF > /etc/systemd/system/layeredge.service
[Unit]
Description=LayerEdge CLI Light Node bởi Peter Tran
After=network.target

[Service]
ExecStart=$(pwd)/layeredge-cli
WorkingDirectory=$(pwd)
Restart=always
User=$(whoami)
EnvironmentFile=$(pwd)/.env

[Install]
WantedBy=multi-user.target
EOF"

# Bước 10: Khởi động và kích hoạt dịch vụ
echo "Khởi động node LayerEdge..."
sudo systemctl daemon-reload
sudo systemctl enable layeredge.service
sudo systemctl start layeredge.service

# Thông báo hoàn tất
echo "Peter Tran, LayerEdge CLI Light Node đã được cài đặt và khởi động thành công!"
echo "Kiểm tra trạng thái: sudo systemctl status layeredge.service"
echo "Xem log: journalctl -u layeredge.service -f"
echo "Cảm ơn bạn đã sử dụng script của Peter Tran!"
