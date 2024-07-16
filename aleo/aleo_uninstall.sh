#!/bin/bash

# aleo各池子卸载服务脚本

project=$1

case "${project}" in
    "f2pool")
        ;;
    "zkrush")
        ;;
    "apool")
        ;;
    *)
        echo "项目输入异常，请重试"
        exit 1
        ;;
esac

# 根路径
BASE_DIR="/root/aleo/""${project}""/"

# 检查是否以root用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以root用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。"
    exit 1
fi

# 停止服务
if [ -e  /lib/systemd/system/aleo-miner-"${project}".service ]; then
  systemctl disable aleo-miner-"${project}" && systemctl stop aleo-miner-"${project}"
  rm -f /lib/systemd/system/aleo-miner-"${project}".service
fi

if [ -d  "${BASE_DIR}" ]; then
  rm -rf "${BASE_DIR}"
fi

echo "${project}""相关数据和服务卸载完毕"
