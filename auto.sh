#!/bin/bash

# Cập nhật hệ thống
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl git build-essential pkg-config libssl-dev

# Cài Go
wget https://go.dev/dl/go1.21.8.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.8.linux-amd64.tar.gz
echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.bashrc
source ~/.bashrc

# Cài Rust và Risc0
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env
cargo install cargo-risczero
risczero install

# Tải mã nguồn
git clone https://github.com/Layer-Edge/light-node.git
cd light-node

# Yêu cầu nhập Private Key
echo "Vui lòng nhập Private Key của bạn (ký tự sẽ không hiển thị):"
read -s PRIVATE_KEY
if [ -z "$PRIVATE_KEY" ]; then
    echo "Lỗi: Private Key không được để trống. Script sẽ thoát."
    exit 1
fi

# Tạo file .env với Private Key vừa nhập
cat <<EOF > .env
GRPC_URL=34.31.74.109:9090
CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709
ZK_PROVER_URL=https://layeredge.mintair.xyz/
API_REQUEST_TIMEOUT=100
POINTS_API=https://light-node.layeredge.io
PRIVATE_KEY=$PRIVATE_KEY
EOF

# Biên dịch
go build -o layeredge-cli main.go

# Cấu hình systemd
sudo bash -c "cat <<EOF > /etc/systemd/system/layeredge.service
[Unit]
Description=LayerEdge CLI Light Node
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

# Khởi động dịch vụ
sudo systemctl daemon-reload
sudo systemctl enable layeredge.service
sudo systemctl start layeredge.service

echo "LayerEdge CLI Light Node đã được cài đặt và khởi động."
echo "Kiểm tra trạng thái bằng: sudo systemctl status layeredge.service"
echo "Xem log bằng: journalctl -u layeredge.service -f"
