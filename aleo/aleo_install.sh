#!/bin/bash

# aleo各池子自动执行脚本

download_base_url=$1
project=$2
accountname=$3
workername=$4
mode=$5

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

case "${mode}" in
    "gpu")
        ;;
    "cpu")
        ;;
    *)
        echo "mode输入异常，请重试"
        exit 1
        ;;
esac

if [ -z "${accountname}" ]; then
    echo "账户名不得为空"
    exit 1
fi

if [ -z "${workername}" ]; then
    echo "worker名称不得为空"
    exit 1
fi

if [ -z "${download_base_url}" ]; then
    echo "根下载地址不得为空"
    exit 1
fi

# 根路径
BASE_DIR="/root/aleo/""${project}""/"
SERVER_URL=${download_base_url}"/aleo/""${project}""/"

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

mkdir -p "${BASE_DIR}"

# 下载程序
wget -O "${BASE_DIR}"aleo-miner-"${project}" "${SERVER_URL}"/aleo-miner-"${project}"
if [ $? -ne 0 ]; then
    echo "程序下载异常"
    exit 1
fi
# 授权
chmod -R 744 "${BASE_DIR}"aleo-miner-"${project}"
cd "${BASE_DIR}"

function start_f2pool() {
  # 通过检查其版本来验证节点是否可运行
  echo "版本号：" && "${BASE_DIR}"aleo-miner-"${project}" -v
  if [ $? -ne 0 ]; then
      echo "aleo-miner-${project}程序异常"
      exit 1
  fi

  case "${mode}" in
      "gpu")
          cmd="${BASE_DIR}aleo-miner-${project} -u stratum+tcp://aleo-asia.f2pool.com:4400 -w ${accountname}.${workername} -d 0"
          start_service "${cmd}"
          ;;
      "cpu")
          cmd="${BASE_DIR}aleo-miner-${project} -u stratum+tcp://aleo-asia.f2pool.com:4400 -w ${accountname}.${workername}"
          start_service "${cmd}"
          ;;
      *)
          echo "mode输入异常，请重试"
          exit 1
          ;;
  esac
}

function start_zkrush() {
  # 通过检查其版本来验证节点是否可运行
  echo "版本号：" && "${BASE_DIR}"aleo-miner-"${project}" -v
  if [ $? -ne 0 ]; then
      echo "aleo-miner-${project}程序异常"
      exit 1
  fi

  case "${mode}" in
      "gpu")
          echo "zkrush暂不支持gpu模式"
          exit 1
          ;;
      "cpu")
          cmd="${BASE_DIR}aleo-miner-${project} --pool wss://aleo.zkrush.com:3333 --account ${accountname} --worker-name ${workername}"
          start_service "${cmd}"
          ;;
      *)
          echo "mode输入异常，请重试"
          exit 1
          ;;
  esac
}

function start_apool() {
# 通过检查其版本来验证节点是否可运行
  echo "版本号：" && "${BASE_DIR}"aleo-miner-"${project}" -V
  if [ $? -ne 0 ]; then
      echo "aleo-miner-${project}程序异常"
      exit 1
  fi

  case "${mode}" in
      "gpu")
          cmd="${BASE_DIR}aleo-miner-${project} --pool aleo1.hk.apool.io:9090 --account ${accountname} --worker ${workername} -A aleo -g 0"
          start_service "${cmd}"
          exit 1
          ;;
      "cpu")
          cmd="${BASE_DIR}aleo-miner-${project} --pool aleo1.hk.apool.io:9090 --gpu-off --account ${accountname} --worker ${workername} -A aleo"
          start_service "${cmd}"
          ;;
      *)
          echo "mode输入异常，请重试"
          exit 1
          ;;
  esac
  return
}

function start_service() {
  echo "启动命令：""$1"
  if [ -z "$1" ]; then
      echo "启动命令为空，请检查"
      exit 1
  fi

  echo "[Unit]
Description=${project} Service
Wants=network-online.target
After=network.target network-online.target

[Service]
Type=simple
User=root
Restart=always
RestartSec=5s
ExecStart=${cmd}
LimitNOFILE=1048576
RuntimeDirectory=${project}
RuntimeDirectoryMode=0755

[Install]
WantedBy=multi-user.target
Alias=aleo-miner-${project}.service
" > /lib/systemd/system/aleo-miner-"${project}".service
  systemctl enable aleo-miner-"${project}"
  systemctl start aleo-miner-"${project}"
}

case "${project}" in
    "f2pool")
        start_f2pool ;;
    "zkrush")
        start_zkrush ;;
    "apool")
        start_apool ;;
    *)
        ;;
esac