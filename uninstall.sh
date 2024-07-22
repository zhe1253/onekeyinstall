#!/bin/bash

# 检查是否以 root 权限运行
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# 定义文件路径
SERVICE_FILE="/etc/systemd/system/sing-box.service"
CONFIG_FILE="/root/config.json"
SING_BOX_BIN="/root/sing-box"

# 停止 sing-box 服务
echo "正在停止 sing-box 服务..."
systemctl stop sing-box

# 禁用 sing-box 服务
echo "正在禁用 sing-box 服务..."
systemctl disable sing-box

# 删除 sing-box.service 文件
if [ -f "$SERVICE_FILE" ]; then
    echo "正在删除 $SERVICE_FILE..."
    rm -f "$SERVICE_FILE"
else
    echo "$SERVICE_FILE 不存在，无需删除。"
fi

# 删除 config.json 文件
if [ -f "$CONFIG_FILE" ]; then
    echo "正在删除 $CONFIG_FILE..."
    rm -f "$CONFIG_FILE"
else
    echo "$CONFIG_FILE 不存在，无需删除。"
fi

# 删除 sing-box 二进制文件
if [ -f "$SING_BOX_BIN" ]; then
    echo "正在删除 $SING_BOX_BIN..."
    rm -f "$SING_BOX_BIN"
else
    echo "$SING_BOX_BIN 不存在，无需删除。"
fi

# 重新加载 systemd 配置
echo "正在重新加载 systemd 配置..."
systemctl daemon-reload

echo "sing-box 服务已停止，相关文件已删除。"
