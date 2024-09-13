#!/bin/bash

# osmonitor client自动安装脚本

name=$1
secret=$2
download_base_url=$3
server_url=$4
proc_names=$5

if [ -z "${name}" ]; then
    echo "名称不得为空"
    exit 1
fi

if [ -z "${secret}" ]; then
    echo "secret名称不得为空"
    exit 1
fi

if [ -z "${download_base_url}" ]; then
    echo "根下载地址不得为空"
    exit 1
fi

if [ -z "${server_url}" ]; then
    echo "server_url不得为空"
    exit 1
fi

if [ -z "${proc_names}" ]; then
    echo "proc_names不得为空"
    exit 1
fi

# 根路径
BASE_DIR="/root/osmonitor/"
DOWNLOAD_URL=${download_base_url}"/osmonitor/osmonitor-client"

# 检查是否以root用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以root用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。"
    exit 1
fi

# 停止服务
if [ -e  /lib/systemd/system/osmonitor-client.service ]; then
  systemctl disable osmonitor-client.service && systemctl stop osmonitor-client.service
  rm -f /lib/systemd/system/osmonitor-client.service
fi

if [ -d  "${BASE_DIR}" ]; then
  rm -rf "${BASE_DIR}"
fi

mkdir -p "${BASE_DIR}"

# 下载程序
wget -q -O "${BASE_DIR}"osmonitor-client "${DOWNLOAD_URL}"
if [ $? -ne 0 ]; then
    echo "程序下载异常"
    exit 1
fi

# 授权
chmod -R 744 "${BASE_DIR}"osmonitor-client
cd "${BASE_DIR}"

cmd="${BASE_DIR}osmonitor-client start --name ${name} --secret ${secret} --server-url ${server_url} --proc-names ${proc_names}"

echo "[Unit]
Description=Osmonitor Client Service
Wants=network-online.target
After=network.target network-online.target

[Service]
Type=simple
User=root
Restart=always
RestartSec=5s
ExecStart=${cmd}
LimitNOFILE=1048576
RuntimeDirectory=osmonitor
RuntimeDirectoryMode=0755

[Install]
WantedBy=multi-user.target
Alias=osmonitor-client.service
" > /lib/systemd/system/osmonitor-client.service
  
systemctl enable osmonitor-client.service
systemctl start osmonitor-client.service