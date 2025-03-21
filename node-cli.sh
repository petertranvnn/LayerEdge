#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m'

# Hiển thị "PETERTRAN"
echo -e '\e[34m'
echo -e "██████╗ ███████╗████████╗███████╗██████╗ ████████╗██████╗  █████╗ ███╗   ██╗"
echo -e "██╔══██╗██╔════╝╚══██╔══╝██╔════╝██╔══██╗╚══██╔══╝██╔══██╗██╔══██╗████╗  ██║"
echo -e "██████╔╝█████╗     ██║   █████╗  ██████╔╝   ██║   ██████╔╝███████║██╔██╗ ██║"
echo -e "██╔═══╝ ██╔══╝     ██║   ██╔══╝  ██╔══██╗   ██║   ██╔══██╗██╔══██║██║╚██╗██║"
echo -e "██║     ███████╗   ██║   ███████╗██║  ██║   ██║   ██║  ██║██║  ██║██║ ╚████║"
echo -e "╚═╝     ╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝"
echo -e '\e[0m'
echo -e "Chào mừng bạn đến chương trình đu đỉnh node/validator" 
sleep 5

echo -e "🚀 Bắt đầu quá trình cài đặt..."
rm -rf $HOME/light-node
echo -e "🔗 Đang sao chép kho lưu trữ..."
git clone https://github.com/Layer-Edge/light-node.git && echo -e "✅ Đã sao chép kho lưu trữ!"
cd light-node
echo -e "📥 Đang tải và cài đặt các phụ thuộc..."
curl -L https://risczero.com/install | bash && echo -e "✅ Đã cài đặt các phụ thuộc!"
source "/root/.bashrc"
echo -e "🔄 Áp dụng các biến môi trường..."
GRPC_URL=grpc.testnet.layeredge.io:9090
CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709
ZK_PROVER_URL=http://127.0.0.1:3001
API_REQUEST_TIMEOUT=100
POINTS_API=http://127.0.0.1:8080
echo -e "🔑 Vui lòng nhập khóa riêng của bạn: "
read PRIVATE_KEY
echo -e "✅ Đã thiết lập khóa riêng!"
export PRIVATE_KEY

echo -e "🛠️ Xây dựng và chạy risc0-merkle-service..."
cd risc0-merkle-service
cargo build && screen -dmS risc0-service cargo run && echo -e "🚀 risc0-merkle-service đang chạy trong một phiên screen!"

echo -e "🖥️ Khởi động máy chủ light-node trong một phiên screen..."
cd .. # Quay lại thư mục light-node
cargo build && screen -dmS light-node cargo run && echo -e "🚀 Máy chủ light-node đang chạy trong một phiên screen!"

echo -e "🎉 Hoàn tất cài đặt! Các máy chủ risc0 và light-node đang chạy độc lập trong các phiên screen!"
echo -e "Chạy light-node của bạn ngay bây giờ!"
