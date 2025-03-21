#!/bin/bash

# Script tự động cài đặt và chạy LayerEdge Light Node
# Tác giả: Peter Tran
# Ngày: 21/03/2025

# ASCII Art "Peter Tran"
echo -e "\e[32m"
cat << "EOF"
  ____      _            
 |  _ \    (_)           
 | |_) | __ _ _ __   __ _ 
 |  _ < / _` | '_ \ / _` |
 | |_) | (_| | | | | (_| |
 |____/ \__,_|_| |_|__, |
                    __/ |
                   |____/
EOF
echo -e "\e[0m"
echo "Chào mừng bạn đến với script cài đặt LayerEdge Light Node bởi Peter Tran!"

# Kiểm tra quyền root
if [ "$EUID" -ne 0 ]; then
    echo "Vui lòng chạy script này với quyền root (sudo)!"
    exit 1
fi

# Cập nhật hệ thống
echo "Đang cập nhật hệ thống..."
apt update && apt upgrade -y

# Cài đặt các gói cần thiết
echo "Đang cài đặt các công cụ cần thiết..."
apt install -y curl wget git build-essential

# Cài đặt Node.js (yêu cầu cho một số script LayerEdge)
echo "Đang cài đặt Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

# Tải và cài đặt LayerEdge CLI
echo "Đang tải LayerEdge CLI từ nguồn chính thức..."
wget -O layeredge-cli.sh https://raw.githubusercontent.com/TheyCallMeSecond/Layeredge-CLI-manager/refs/heads/main/layeredge-cli.sh
chmod +x layeredge-cli.sh

# Cấu hình biến môi trường
echo "Đang cấu hình biến môi trường..."
cat << EOF > .env
GRPC_URL=grpc.testnet.layeredge.io:9090
CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709
ZK_PROVER_URL=http://127.0.0.1:3001
API_REQUEST_TIMEOUT=100
POINTS_API=http://127.0.0.1:8080
PRIVATE_KEY='your-private-key-here'
EOF

# Tạo thư mục log
echo "Đang tạo thư mục log..."
mkdir -p /var/log/layeredge
touch /var/log/layeredge/node.log
touch /var/log/layeredge/node-error.log

# Tạo service cho LayerEdge Node
echo "Đang tạo systemd service..."
cat << EOF > /etc/systemd/system/layeredge-node.service
[Unit]
Description=LayerEdge Light Node Service by Peter Tran
After=network.target

[Service]
ExecStart=/bin/bash /root/layeredge-cli.sh start
Restart=always
User=root
StandardOutput=append:/var/log/layeredge/node.log
StandardError=append:/var/log/layeredge/node-error.log

[Install]
WantedBy=multi-user.target
EOF

# Kích hoạt và khởi động service
echo "Đang kích hoạt và khởi động LayerEdge Node..."
systemctl daemon-reload
systemctl enable layeredge-node.service
systemctl start layeredge-node.service

# Kiểm tra trạng thái
echo "Kiểm tra trạng thái node..."
systemctl status layeredge-node.service | head -n 10

# Hướng dẫn sử dụng
echo -e "\e[33m"
echo "Cài đặt hoàn tất! Dưới đây là các lệnh hữu ích:"
echo "  - Kiểm tra trạng thái: systemctl status layeredge-node.service"
echo "  - Dừng node: systemctl stop layeredge-node.service"
echo "  - Khởi động lại: systemctl restart layeredge-node.service"
echo "  - Xem log: tail -f /var/log/layeredge/node.log"
echo -e "\e[0m"

echo "Chúc bạn kiếm được nhiều EDGE Points! - Peter Tran"
