#!/bin/bash

# Thoát nếu có lỗi
set -e

# Kiểm tra quyền root
if [ "$EUID" -ne 0 ]; then
    echo "Lỗi: Vui lòng chạy script này với quyền root (sudo)."
    exit 1
fi

echo "Bắt đầu cài đặt LayerEdge CLI Light Node..."

# Cập nhật hệ thống và cài đặt phụ thuộc
apt update && apt upgrade -y
apt install -y curl git build-essential pkg-config libssl-dev

# Cài Rust 1.81.0
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"
rustup install 1.81.0
rustup default 1.81.0

# Cài Risc0
curl -L https://risczero.com/install | bash
rzup install

# Tải và biên dịch LayerEdge CLI
git clone https://github.com/Layer-Edge/light-node.git /opt/layeredge-light-node
cd /opt/layeredge-light-node
cargo build --release

# Thiết lập biến môi trường
cat << EOF > /opt/layeredge-light-node/.env
GRPC_URL=grpc.testnet.layeredge.io:9090
CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709
ZK_PROVER_URL=http://127.0.0.1:3001
API_REQUEST_TIMEOUT=100
POINTS_API=http://127.0.0.1:8080
PRIVATE_KEY='cli-node-private-key'
EOF
echo "Vui lòng thay 'cli-node-private-key' trong /opt/layeredge-light-node/.env bằng khóa riêng của bạn."

# Tạo dịch vụ systemd
cat << EOF > /etc/systemd/system/layeredge-light-node.service
[Unit]
Description=Dịch vụ LayerEdge CLI Light Node
After=network.target

[Service]
EnvironmentFile=/opt/layeredge-light-node/.env
ExecStart=/opt/layeredge-light-node/target/release/light-node
WorkingDirectory=/opt/layeredge-light-node
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

# Kích hoạt dịch vụ
systemctl daemon-reload
systemctl enable layeredge-light-node.service
systemctl start layeredge-light-node.service

echo "Cài đặt hoàn tất! Theo dõi nhật ký với: journalctl -u layeredge-light-node.service -f"
