#!/bin/bash

# 提示用户输入端口
read -p "请输入监听端口: " PORT

# 提示是否继续搭建
read -p "是否确认搭建 VLESS Reality？(y/n): " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo "已取消安装。"
    exit 0
fi

# Step 1: 更新系统
echo "开始更新系统..."
sudo apt update && sudo apt upgrade -y
if [[ $? -ne 0 ]]; then
    echo "系统更新失败，退出。"
    exit 1
fi
echo "[step 1完成]"

# Step 2: 安装 Xray
echo "开始安装 Xray..."
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
if [[ $? -ne 0 ]]; then
    echo "Xray 安装失败，退出。"
    exit 1
fi
echo "[step 2完成]"

# Step 3: 生成 UUID 和密钥
UUID=$(xray uuid)
if [[ -z "$UUID" ]]; then
    echo "生成 UUID 失败，退出。"
    exit 1
fi

KEY_INFO=$(xray x25519)
PRIVATE_KEY=$(echo "$KEY_INFO" | grep "Private key" | awk -F ': ' '{print $2}')
PUBLIC_KEY=$(echo "$KEY_INFO" | grep "Public key" | awk -F ': ' '{print $2}')
if [[ -z "$PRIVATE_KEY" || -z "$PUBLIC_KEY" ]]; then
    echo "生成密钥失败，退出。"
    exit 1
fi

# Step 4: 输入目标网站
read -p "请输入目标网站（如 www.cloudflare.com）: " DEST
if [[ -z "$DEST" ]]; then
    echo "目标网站不能为空，退出。"
    exit 1
fi

# Step 5: 写入配置文件
mkdir -p /usr/local/etc/xray

cat > /usr/local/etc/xray/config.json <<EOF
{{
  "inbounds": [
    {{
      "port": {PORT},
      "protocol": "vless",
      "settings": {{
        "clients": [
          {{
            "id": "{UUID}",
            "flow": "xtls-rprx-vision",
            "level": 0,
            "email": "love@love.com"
          }}
        ],
        "decryption": "none",
        "fallbacks": []
      }},
      "streamSettings": {{
        "network": "tcp",
        "security": "reality",
        "realitySettings": {{
          "show": false,
          "dest": "{DEST}:443",
          "xver": 0,
          "serverNames": [
            "{DEST}"
          ],
          "privateKey": "{PRIVATE_KEY}",
          "shortIds": [
            "0123456789abcdef"
          ]
        }}
      }}
    }}
  ],
  "outbounds": [
    {{
      "protocol": "freedom",
      "settings": {{}}
    }}
  ]
}}
EOF

# 重启 Xray 服务
echo "正在重启 Xray 服务..."
sudo systemctl restart xray
sleep 1
echo "Xray 服务状态如下："
sudo systemctl status xray --no-pager

# 成功提示
echo "================ 搭建成功 ================"
echo "UUID: $UUID"
echo "Public Key: $PUBLIC_KEY"
echo "ShortId: 0123456789abcdef"
echo "配置文件已写入: /usr/local/etc/xray/config.json"
echo "=========================================="