#!/bin/bash

# 检查是否以 root 权限运行
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

SERVICE_FILE="/etc/systemd/system/sing-box.service"
CONFIG_FILE="/root/config.json"
SING_BOX_BIN="/root/sing-box"

# 检查 sing-box.service 是否已存在
if [ -f "$SERVICE_FILE" ]; then
    echo "sing-box 服务已存在，无需重新安装。"
else
    # 创建 sing-box 服务文件
    cat <<EOF > "$SERVICE_FILE"
[Unit]
Description=sing-box Service
Documentation=https://sing-box.sagernet.org/
After=network.target nss-lookup.target
Wants=network.target

[Service]
Type=simple
ExecStart=$SING_BOX_BIN run -c $CONFIG_FILE
Restart=always
RestartSec=3s
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF

    # 检查是否已存在配置文件
    if [ ! -f "$CONFIG_FILE" ]; then
        # 创建 sing-box 配置文件
        cat <<EOF > "$CONFIG_FILE"
{
  "log": {
    "level": "info",
    "timestamp": true
  },
  "inbounds": [
    {
      "type": "vless",
      "tag": "vless-in",
      "listen": "::",
      "listen_port": 8543,
      "sniff": true,
      "sniff_override_destination": true,
      "users": [
        {
          "name": "",
          "uuid": "b58b7106-1067-45e9-a8db-8adca1a70ae1",
          "flow": "xtls-rprx-vision"
        }
      ],
      "tls": {
        "enabled": true,
        "server_name": "nijigen-works.jp",
        "reality": {
          "enabled": true,
          "handshake": {
            "server": "nijigen-works.jp",
            "server_port": 443
          },
          "private_key": "2KZ4uouMKgI8nR-LDJNP1_MHisCJOmKGj9jUjZLncVU",
          "short_id": "a1f60e0f27d84fa6"
        }
      }
    }
  ],
  "outbounds": [
    {
      "type": "direct",
      "tag": "direct"
    }
  ]
}
EOF
    else
        echo "配置文件已存在，跳过创建。"
    fi

    # 重新加载 systemd 配置并启用 sing-box 服务
    systemctl daemon-reload && systemctl enable sing-box || {
        echo "启用 sing-box 服务失败"
        exit 1
    }
    echo "sing-box 服务已创建并启用"
fi

# 获取最新版本的 Sing-box 的下载链接
download_link=$(curl -s "https://api.github.com/repos/SagerNet/sing-box/releases" | grep -oP '"browser_download_url": "\K(.*?linux-amd64.tar\.gz)' | head -n 1)

# 下载最新版本的 Sing-box
wget -O sing-box.tar.gz "$download_link" || {
    echo "下载 Sing-box 失败"
    exit 1
}

# 解压下载的 Sing-box 文件
tar zxvf sing-box.tar.gz || {
    echo "解压 Sing-box 失败"
    exit 1
}

# 停止当前正在运行的 Sing-box 服务（如果有的话）
systemctl stop sing-box

# 备份现有的 sing-box 文件（如果存在）
if [ -f "$SING_BOX_BIN" ]; then
    mv "$SING_BOX_BIN" "${SING_BOX_BIN}.bak"
fi

# 将新的 sing-box 文件移动到 /root 目录
mv sing-box-*-linux-amd64/sing-box "$SING_BOX_BIN" || {
    echo "移动 sing-box 文件失败"
    exit 1
}

# 设置正确的权限
chmod +x "$SING_BOX_BIN"

# 重新启动 Sing-box 服务
systemctl restart sing-box || {
    echo "重启 sing-box 服务失败"
    exit 1
}

# 清理下载和解压产生的文件
rm -f sing-box.tar.gz
rm -rf sing-box-*-linux-amd64

echo "Sing-box 更新并重新安装完成。"
echo "sing-box 安装和配置已完成"
