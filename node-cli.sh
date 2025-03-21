#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m'

# Hiển thị banner và thông báo chào mừng
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
cd $HOME/light-node
echo -e "📥 Đang tải và cài đặt các phụ thuộc..."
curl -L https://risczero.com/install | bash && echo -e "✅ Đã cài đặt phụ thuộc!"
source "/root/.bashrc"
echo -e "🔄 Áp dụng các biến môi trường..."
echo "GRPC_URL=grpc.testnet.layeredge.io:9090" > .env
echo "CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709" >> .env
echo "ZK_PROVER_URL=http://127.0.0.1:3001" >> .env
echo "API_REQUEST_TIMEOUT=100" >> .env
echo "POINTS_API=http://127.0.0.1:8080" >> .env
echo -e "🔑 Vui lòng nhập khóa riêng của bạn: "
read PRIVATE_KEY
echo "PRIVATE_KEY=$PRIVATE_KEY" >> .env
echo -e "✅ Đã thiết lập khóa riêng!"

echo -e "🛠️ Biên dịch và chạy risc0-merkle-service..."
cd $HOME/light-node/risc0-merkle-service
cargo build && screen -dmS risc0-service cargo run && echo -e "🚀 risc0-merkle-service đang chạy trong phiên screen!"

echo -e "🖥️ Khởi động máy chủ light-node trong phiên screen..."
cd $HOME/light-node
go build && screen -dmS lightnode ./light-node && echo -e "🚀 Light-node đang chạy trong phiên screen!"

echo -e "🎉 Quá trình cài đặt hoàn tất! Các dịch vụ đang chạy độc lập trong các phiên screen!"
echo -e "Để kiểm tra, sử dụng: ${GREEN}screen -r risc0-service${NC} hoặc ${GREEN}screen -r lightnode${NC}"
