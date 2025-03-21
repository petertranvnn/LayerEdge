#!/bin/bash

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No color

# Display banner
echo -e "${BLUE}"
echo -e "██████╗ ███████╗████████╗███████╗██████╗ ████████╗██████╗  █████╗ ███╗   ██╗"
echo -e "██╔══██╗██╔════╝╚══██╔══╝██╔════╝██╔══██╗╚══██╔══╝██╔══██╗██╔══██╗████╗  ██║"
echo -e "██████╔╝█████╗     ██║   █████╗  ██████╔╝   ██║   ██████╔╝███████║██╔██╗ ██║"
echo -e "██╔═══╝ ██╔══╝     ██║   ██╔══╝  ██╔══██╗   ██║   ██╔══██╗██╔══██║██║╚██╗██║"
echo -e "██║     ███████╗   ██║   ███████╗██║  ██║   ██║   ██║  ██║██║  ██║██║ ╚████║"
echo -e "╚═╝     ╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝"
echo -e "${NC}"
echo -e "${GREEN}Welcome to LayerEdge Light Node!${NC}"
sleep 5

# 1️⃣ Initial setup
echo -e "${YELLOW}🚀 Starting installation...${NC}"
sudo apt update && sudo apt upgrade -y
sudo apt install build-essential git screen net-tools curl telnet -y
echo -e "${GREEN}✅ Basic tools installed!${NC}"

# 2️⃣ Install Go 1.21.6
echo -e "${CYAN}📥 Installing Go 1.21.6...${NC}"
wget https://go.dev/dl/go1.21.6.linux-amd64.tar.gz -O go1.21.6.tar.gz
sudo tar -C /usr/local -xzf go1.21.6.tar.gz
echo "export GOROOT=/usr/local/go" >> ~/.bashrc
echo "export GOPATH=\$HOME/go" >> ~/.bashrc
echo "export PATH=\$GOPATH/bin:\$GOROOT/bin:\$PATH" >> ~/.bashrc
source ~/.bashrc
echo -e "${GREEN}✅ Installed $(go version)!${NC}"

# 3️⃣ Install Rust and Cargo
echo -e "${CYAN}📥 Installing Rust and Cargo...${NC}"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env
sudo apt install cargo -y
echo -e "${GREEN}✅ Installed Rust: $(rustc --version)!${NC}"

# 4️⃣ Install Risc0 Toolchain
echo -e "${CYAN}📥 Installing Risc0 Toolchain...${NC}"
curl -L https://risczero.com/install | bash
export PATH="$PATH:/root/.risc0/bin"
echo "export PATH=\$PATH:/root/.risc0/bin" >> ~/.bashrc
source ~/.bashrc
echo -e "${YELLOW}🔍 Current PATH: $PATH${NC}"
rzup install
if command -v rzup >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Risc0 Toolchain: $(rzup --version)!${NC}"
else
    echo -e "${RED}❌ 'rzup' not found. Exiting...${NC}"
    echo -e "${YELLOW}Manual check: run 'source ~/.bashrc' then 'rzup --help'${NC}"
    exit 1
fi

# 5️⃣ Clone repository
echo -e "${YELLOW}🔗 Cloning repository...${NC}"
rm -rf $HOME/light-node
git clone https://github.com/Layer-Edge/light-node.git $HOME/light-node
cd $HOME/light-node
echo -e "${GREEN}✅ Cloned successfully!${NC}"

# 6️⃣ Configure .env
echo -e "${YELLOW}🔄 Configuring .env...${NC}"
echo -e "${CYAN}🔑 Enter EVM private key (you can use a burner wallet):${NC}"
read -p "Enter private key: " PRIVATE_KEY
echo -e "${CYAN}🔧 Enter GRPC_URL (press Enter for default grpc.testnet.layeredge.io:9090):${NC}"
read -p "GRPC_URL: " GRPC_INPUT
if [ -z "$GRPC_INPUT" ]; then
    GRPC_URL="grpc.testnet.layeredge.io:9090"
else
    GRPC_URL="$GRPC_INPUT"
fi
echo -e "${CYAN}🔧 Choose ZK_PROVER_URL: ${NC}"
echo -e "  1. http://127.0.0.1:3001 (run locally)"
echo -e "  2. layeredge.mintair.xyz (external server)"
read -p "Enter choice (1 or 2): " ZK_CHOICE
if [ "$ZK_CHOICE" == "1" ]; then
    ZK_PROVER_URL="http://127.0.0.1:3001"
    RUN_LOCAL_ZK=1
elif [ "$ZK_CHOICE" == "2" ]; then
    ZK_PROVER_URL="layeredge.mintair.xyz"
    RUN_LOCAL_ZK=0
else
    echo -e "${RED}❌ Invalid choice. Exiting...${NC}"
    exit 1
fi

cat > .env << EOL
GRPC_URL=$GRPC_URL
CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709
ZK_PROVER_URL=$ZK_PROVER_URL
API_REQUEST_TIMEOUT=120000
POINTS_API=light-node.layeredge.io
PRIVATE_KEY=$PRIVATE_KEY
EOL
echo -e "${GREEN}✅ Created .env with GRPC_URL=$GRPC_URL and ZK_PROVER_URL=$ZK_PROVER_URL!${NC}"

# 7️⃣ Check resources and network
echo -e "${YELLOW}🔍 Checking resources...${NC}"
cpu_cores=$(nproc)
memory=$(free -h | awk '/^Mem:/ {print $2}')
echo -e "CPU: $cpu_cores cores"
echo -e "RAM: $memory"
if [ $cpu_cores -lt 2 ] || [ $(free -m | awk '/^Mem:/ {print $2}') -lt 2048 ]; then
    echo -e "${YELLOW}⚠️ VPS may not be powerful enough.${NC}"
fi

echo -e "${YELLOW}🔍 Checking gRPC connection...${NC}"
attempts=0
max_attempts=3
while [ $attempts -lt $max_attempts ]; do
    nc -zv 34.31.74.109 9090 > /tmp/grpc_check 2>&1
    if grep -q "succeeded" /tmp/grpc_check; then
        echo -e "${GREEN}✅ Connected to grpc.testnet.layeredge.io:9090 successfully!${NC}"
        rm /tmp/grpc_check
        break
    else
        error=$(cat /tmp/grpc_check)
        echo -e "${RED}❌ Attempt $((attempts + 1)): Could not connect to grpc.testnet.layeredge.io:9090. Error: $error${NC}"
        attempts=$((attempts + 1))
        sleep 5
    fi
done
if [ $attempts -eq $max_attempts ]; then
    echo -e "${RED}❌ Failed to connect after $max_attempts attempts.${NC}"
    echo -e "${YELLOW}Manual checks:${NC}"
    echo -e "  - nc -zv 34.31.74.109 9090"
    echo -e "  - telnet 34.31.74.109 9090"
    echo -e "  - ping grpc.testnet.layeredge.io"
    echo -e "${YELLOW}Testnet server may be offline. Contact LayerEdge on Telegram: https://t.me/NTExhaust${NC}"
    rm /tmp/grpc_check
    exit 1
fi

# 8️⃣ Clean up old screens
echo -e "${YELLOW}🧹 Cleaning up old screens...${NC}"
screen -ls | grep Detached | awk '{print $1}' | xargs -I {} screen -X -S {} quit
echo -e "${GREEN}✅ Old screens cleared!${NC}"

# 9️⃣ Run Risc0 Merkle Service (if local)
if [ "$RUN_LOCAL_ZK" -eq 1 ]; then
    echo -e "${YELLOW}🛠️ Compiling Risc0 Merkle Service...${NC}"
    cd $HOME/light-node/risc0-merkle-service
    cargo build --release
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Risc0 Merkle Service compilation failed.${NC}"
        exit 1
    fi

    echo -e "${YELLOW}🚀 Starting Risc0 Merkle Service...${NC}"
    attempts=0
    max_attempts=3
    while [ $attempts -lt $max_attempts ]; do
        if netstat -tuln | grep -q ":3001"; then
            echo -e "${YELLOW}🔍 Port 3001 is in use. Killing old process...${NC}"
            kill $(lsof -t -i:3001)
        fi
        screen -S layeredge -dm bash -c "cargo run --release > $HOME/risc0-merkle.log 2>&1"
        sleep 60
        if screen -ls | grep -q "layeredge" && curl -s http://127.0.0.1:3001 >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Risc0 Merkle Service running on port 3001!${NC}"
            echo -e "Log: ${CYAN}$HOME/risc0-merkle.log${NC}"
            break
        else
            echo -e "${RED}❌ Attempt $((attempts + 1)) failed:${NC}"
            cat $HOME/risc0-merkle.log
            attempts=$((attempts + 1))
            sleep 5
        fi
    done
    if [ $attempts -eq $max_attempts ]; then
        echo -e "${RED}❌ Could not start Risc0 Merkle Service:${NC}"
        cat $HOME/risc0-merkle.log
        exit 1
    fi
else
    echo -e "${YELLOW}🔧 Using external ZK_PROVER_URL: $ZK_PROVER_URL. Skipping local run.${NC}"
fi

# 10️⃣ Compile and run Light Node
echo -e "${YELLOW}🖥️ Compiling and running Light Node...${NC}"
cd $HOME/light-node
go build
if [ $? -eq 0 ] && [ -f ./light-node ]; then
    screen -S light-node -dm bash -c "./light-node > $HOME/light-node.log 2>&1"
    sleep 120
    if screen -ls | grep -q "light-node"; then
        echo -e "${GREEN}✅ Light Node is running!${NC}"
        echo -e "Log: ${CYAN}$HOME/light-node.log${NC}"
    else
        echo -e "${RED}❌ Light Node failed:${NC}"
        cat $HOME/light-node.log
        exit 1
    fi
else
    echo -e "${RED}❌ Light Node compilation failed.${NC}"
    exit 1
fi

# 11️⃣ Completion
echo -e "${GREEN}🎉 Installation complete!${NC}"
echo -e "Services running:"
if [ "$RUN_LOCAL_ZK" -eq 1 ]; then
    echo -e "  - Risc0 Merkle Service: ${CYAN}screen -r layeredge${NC}"
fi
echo -e "  - Light Node: ${CYAN}screen -r light-node${NC}"
echo -e "${YELLOW}🔍 List screens:${NC}"
screen -ls
echo -e "${YELLOW}💡 Check logs:${NC}"
if [ "$RUN_LOCAL_ZK" -eq 1 ]; then
    echo -e "  - Risc0: ${CYAN}cat $HOME/risc0-merkle.log${NC}"
fi
echo -e "  - Light Node: ${CYAN}cat $HOME/light-node.log${NC}"
