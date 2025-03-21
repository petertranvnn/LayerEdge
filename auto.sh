#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo -e '\e[34m'
echo -e '   ____ ______   _______ ______   _    _ '
echo -e '  / __ \  __ \ \ / /_   _|  _ \ | |  | |'
echo -e ' | |  | | |__) \ V /  | | | |_) || |__| |'
echo -e ' | |__| |  ___/ > <   | | |  _ < |  __  |'
echo -e '  \____/|_|    /_/\_| |_| |_| \_|_|  |_|'
echo -e '\e[0m'
sleep 5

echo -e "🚀 Bắt đầu quá trình cài đặt..."
rm -rf $HOME/light-node
echo -e "🔗 Đang sao chép kho lưu trữ..."
git clone https://github.com/Layer-Edge/light-node.git && echo -e "✅ Đã sao chép kho lưu trữ!"
cd light-node
echo -e "📥 Đang tải và cài đặt các phụ thuộc..."
curl -L https://risczero.com/install | bash && echo -e "✅ Đã cài đặt các phụ thuộc!"
source "/root/.bashrc"
echo -e "🔄 Đang áp dụng các biến môi trường..."
export GRPC_URL=34.31.74.109:9090
export CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709
export ZK_PROVER_URL=http://127.0.0.1:3001
export API_REQUEST_TIMEOUT=100
export POINTS_API=http://127.0.0.1:8080
echo -e "🔑 Vui lòng nhập khóa riêng của bạn: "
read PRIVATE_KEY
echo -e "✅ Đã thiết lập khóa riêng!"
export PRIVATE_KEY

echo -e "🛠️ Đang xây dựng và chạy risc0-merkle-service..."
cd risc0-merkle-service
cargo build && screen -dmS risc0-service cargo run && echo -e "🚀 risc0-merkle-service đang chạy trong một phiên màn hình!"

echo -e "🖥️ Đang khởi động máy chủ light-node trong một phiên màn hình..."

echo -e "🎉 Hoàn tất cài đặt! Cả hai máy chủ đang chạy độc lập trong các phiên màn hình!"
