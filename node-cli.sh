#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
NC='\033[0m'

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

if [ -z "$PRIVATE_KEY" ] && [ $# -eq 0 ]; then
    echo -e "${RED}❌ Lỗi: Vui lòng cung cấp PRIVATE_KEY qua biến môi trường hoặc tham số dòng lệnh.${NC}"
    echo -e "Ví dụ: PRIVATE_KEY=your_private_key_here ./auto.sh"
    echo -e "Hoặc: ./auto.sh your_private_key_here"
    exit 1
elif [ $# -eq 1 ]; then
    PRIVATE_KEY=$1
fi
echo -e "✅ Đã thiết lập khóa riêng: $PRIVATE_KEY"
export PRIVATE_KEY

echo -e "🛠️ Đang thêm phụ thuộc để tạo khóa công khai..."
echo '[dependencies]
secp256k1 = "0.24"
hex = "0.4"' >> Cargo.toml

echo -e "📝 Tạo công cụ xuất khóa công khai..."
cat << 'INNEREOF' > get_pubkey.rs
use secp256k1::{SecretKey, PublicKey};
use std::env;

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() < 2 {
        eprintln!("Vui lòng cung cấp khóa riêng dưới dạng hex!");
        std::process::exit(1);
    }
    let private_key_hex = &args[1];
    let private_key_bytes = hex::decode(private_key_hex).expect("Chuỗi hex không hợp lệ");
    let secp = secp256k1::Secp256k1::new();
    let secret_key = SecretKey::from_slice(&private_key_bytes).expect("Khóa riêng không hợp lệ");
    let public_key = PublicKey::from_secret_key(&secp, &secret_key);
    println!("{}", public_key);
}
INNEREOF

echo -e "🔑 Đang tạo khóa công khai từ khóa riêng..."
cargo build --bin get_pubkey
PUBLIC_KEY=$(cargo run --bin get_pubkey -- $PRIVATE_KEY 2>/dev/null)
if [ -z "$PUBLIC_KEY" ]; then
    echo -e "${RED}❌ Lỗi: Không thể tạo khóa công khai. Vui lòng kiểm tra khóa riêng của bạn.${NC}"
    exit 1
else
    echo -e "✅ Khóa công khai: $PUBLIC_KEY"
    export PUBLIC_KEY
fi

echo -e "🛠️ Xây dựng và chạy risc0-merkle-service..."
cd risc0-merkle-service
cargo build && screen -dmS risc0-service cargo run && echo -e "🚀 risc0-merkle-service đang chạy trong một phiên screen!"

echo -e "🖥️ Khởi động máy chủ light-node trong một phiên screen..."
cd .. # Quay lại thư mục light-node
cargo build && screen -dmS light-node cargo run && echo -e "🚀 Máy chủ light-node đang chạy trong một phiên screen!"

echo -e "🎉 Hoàn tất cài đặt! Các máy chủ risc0 và light-node đang chạy độc lập trong các phiên screen!"
echo -e "Chạy light-node của bạn ngay bây giờ!"
