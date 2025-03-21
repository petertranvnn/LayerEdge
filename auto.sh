#!/bin/bash

# Script tự động cài đặt LayerEdge CLI Light Node trên Ubuntu 24.10
# Tác giả: Grok (xAI)
# Ngày: 21 tháng 03 năm 2025
# Tương thích với Ubuntu 24.10

# Thoát nếu có lỗi
set -e

# Màu sắc cho thông báo
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # Không màu

# Kiểm tra quyền root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Lỗi: Vui lòng chạy script này với quyền root (sudo).${NC}"
    exit 1
fi

echo -e "${GREEN}Bắt đầu cài đặt LayerEdge CLI Light Node...${NC}"

# Đợi khóa dpkg nếu bị chiếm dụng
echo "Kiểm tra và giải phóng khóa dpkg (nếu cần)..."
for i in {1..10}; do
    if fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; then
        echo "Đang đợi khóa dpkg... ($i/10)"
        sleep 5
    else
        break
    fi
done
if fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; then
    echo -e "${RED}Lỗi: Không thể giải phóng khóa dpkg. Vui lòng dừng các tiến trình apt khác và thử lại.${NC}"
    exit 1
fi

# Cập nhật hệ thống và cài đặt phụ thuộc
echo "Đang cập nhật hệ thống và cài đặt các gói phụ thuộc..."
apt update && apt upgrade -y
apt install -y curl git build-essential pkg-config libssl-dev

# Cài đặt Rust 1.81.0 và cập nhật PATH
echo "Đang cài đặt Rust 1.81.0..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain 1.81.0 -q
export PATH="$HOME/.cargo/bin:$PATH"
rustc --version || { echo -e "${RED}Lỗi: Rust cài đặt thất bại.${NC}"; exit 1; }

# Cài đặt Risc0 và cập nhật PATH
echo "Đang cài đặt Risc0..."
curl -L https://risczero.com/install | bash -s -- -q
export PATH="$HOME/.risc0/bin:$PATH"
rzup install || { echo -e "${RED}Lỗi: Risc0 cài đặt thất bại.${NC}"; exit 1; }

# Tải mã nguồn LayerEdge light-node
echo "Đang tải mã nguồn LayerEdge light-node..."
git clone https://github.com/Layer-Edge/light-node.git /opt/layeredge-light-node || { echo -e "${RED}Lỗi: Không thể clone repository.${NC}"; exit 1; }
cd /opt/layeredge-light-node

# Biên dịch light node
echo "Đang biên dịch LayerEdge CLI Light Node..."
cargo build --release || { echo -e "${RED}Lỗi: Biên dịch thất bại.${NC}"; exit 1; }

# Thiết lập biến môi trường
echo "Đang thiết lập biến môi trường..."
cat << EOF > /opt/layeredge-light-node/.env
GRPC_URL=grpc.testnet.layeredge.io:9090
CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709
ZK_PROVER_URL=http://127.0.0.1:3001
API_REQUEST_TIMEOUT=100
POINTS_API=http://127.0.0.1:8080
PRIVATE_KEY='cli-node-private-key'
EOF

echo -e "${GREEN}Vui lòng thay 'cli-node-private-key' trong /opt/layeredge-light-node/.env bằng khóa riêng của bạn sau khi script hoàn tất.${NC}"

# Tạo dịch vụ systemd
echo "Đang tạo dịch vụ systemd..."
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

# Kích hoạt và khởi động dịch vụ
echo "Đang kích hoạt và khởi động dịch vụ LayerEdge..."
systemctl daemon-reload
systemctl enable layeredge-light-node.service
systemctl start layeredge-light-node.service

# Kiểm tra trạng thái dịch vụ
echo "Đang kiểm tra trạng thái dịch vụ..."
systemctl status layeredge-light-node.service --no-pager

echo -e "${GREEN}Cài đặt LayerEdge CLI Light Node hoàn tất thành công!${NC}"
echo "Theo dõi nhật ký với lệnh: journalctl -u layeredge-light-node.service -f"
echo "Đảm bảo dịch vụ Merkle đang chạy trên ZK_PROVER_URL (mặc định: http://127.0.0.1:3001)."
echo "Khởi động lại hệ thống nếu cần để áp dụng kernel mới: sudo reboot"
