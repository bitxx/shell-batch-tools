#!/bin/bash

# > 覆盖
# >> 追加

source .env

# 下载或者更新脚本使用的根路径，先检查本地环境变量是否有配置，没有则读取默认的
# 地址必须以/结尾
if [ -z "$SHELL_BASE_URL" ]; then
  SHELL_BASE_URL="https://raw.githubusercontent.com/bitxx/shell-batch-tools/main/"
fi

# 根目录
BASE_DIR=$(pwd)

# 服务器列表文件，每行一个服务器IP或域名
SERVER_LIST_IP=$BASE_DIR/server_list_ip.csv

# 密码修改
# 服务器ip和对应要修改的密码列表文件
SERVER_LIST_PWD=$BASE_DIR/server_list_pwd.csv

# SSL相关变量
# SSL根目录
SSL_BASE_DIR=$BASE_DIR/tmp/sslkey
SSL_KEY=$SSL_BASE_DIR/cert.key
SSL_PEM=$SSL_BASE_DIR/cert.pem

# SSH相关变量
# SSH根目录目录
SSH_BASE_DIR=$BASE_DIR/tmp/sshkey
# SSH新公钥文件路径
SSH_PUB_KEY=$SSH_BASE_DIR/id_rsa.pub
# SSH新私钥路径
SSH_PRIVATE_KEY=$SSH_BASE_DIR/id_rsa
# 服务器ssh对应的私钥，用于服务器远程分发
SSH_SERVER_PRIVATE_KEY=$BASE_DIR/id_rsa.server

# osmonitor cli服务器列表
SERVER_LIST_OSMONITOR_CLIENT=$BASE_DIR/server_list_osmonitor_cli.csv
# aleo服务器列表
SERVER_LIST_ALEO=$BASE_DIR/server_list_aleo.csv

function ssl_gen_key() {
  if [ -e  "$SSH_PRIVATE_KEY" ]; then
      echo "检测到当前脚本目录已经存在id_rsa，继续执行则会覆盖该文件，是否继续？[Y/N]"
      read -r -p "请确认: " response

      case "$response" in
          [yY][eE][sS]|[yY])
              ;;
          *)
              exit 1
              ;;
      esac
  fi

  if [ ! -d "$SSL_BASE_DIR" ]; then
      mkdir -p "$SSL_BASE_DIR"
  fi

  openssl genrsa 2048 > "$SSL_KEY"
  openssl req -new -x509 -key "$SSL_KEY" -days 365 > "$SSL_PEM"
  echo "ssl证书生成成功，请及时备份相应文件。文件所在目录：$SSL_BASE_DIR"
}

function ssh_gen_key() {
  if [ -e  "$SSH_PRIVATE_KEY" ]; then
      echo "检测到当前脚本目录已经存在id_rsa，继续执行则会覆盖该文件，是否继续？[Y/N]"
      read -r -p "请确认: " response
      case "$response" in
          [yY][eE][sS]|[yY])
              ;;
          *)
              exit 1
              ;;
      esac
  fi

  if [ ! -d "$SSH_BASE_DIR" ]; then
      mkdir -p "$SSH_BASE_DIR"
  fi

  ssh-keygen -t rsa -f "$SSH_PRIVATE_KEY" -N ""
  echo "ssh密钥生成成功，请及时备份相应文件。文件所在目录：$SSH_BASE_DIR"
}

function batch_ssh_update_key() {
  # 参考该文章进一步完善：https://blog.csdn.net/qq_35273918/article/details/121165992

  if [ ! -e  "$SSH_SERVER_PRIVATE_KEY" ] || [ ! -e  "$SSH_PUB_KEY" ] || [ ! -e  "$SERVER_LIST_IP" ] ; then
    echo "请先确保 id_rsa.pub、id_rsa.server、server_list_ip.csv 这3个文件全在当前脚本目录位置"
    return
  fi

  chmod -R 600 "$SSH_SERVER_PRIVATE_KEY"

  # 读取服务器列表文件
  echo "服务器公钥更新中..."
  i=0
  while read -r server; do
    ((i++))
    ip=$(echo "$server" | cut -d',' -f1)
    port=$(echo "$server" | cut -d',' -f2)

    echo "正在更新第${i}行，ip => ${ip}"

    if [ -z "$ip" ] || [ -z "$port" ] ; then
      echo "解析格式异常"
      continue
    fi
    # 将公钥追加到远程服务器的authorized_keys文件中
    cat < "$SSH_PUB_KEY" | ssh -o StrictHostKeyChecking=no -p"$port" -i "$SSH_SERVER_PRIVATE_KEY" root@"$ip" "umask 077; mkdir -p ~/.ssh && touch ~/.ssh/authorized_keys && chmod -R go= ~/.ssh && cat > ~/.ssh/authorized_keys"
    if [ $? -ne 0 ]; then
        echo "命令更新异常"
    fi
  done < "$SERVER_LIST_IP"
  echo "所有服务器的SSH公钥已更新完成"
}

function batch_ssh_update_pwd() {
  # 参考 https://blog.51cto.com/u_16077267/9374597

  if [ ! -e  "$SSH_SERVER_PRIVATE_KEY" ] || [ ! -e  "$SERVER_LIST_PWD" ] ; then
    echo "请先确保 id_rsa.server、server_list_pwd.csv 这2个文件在当前脚本目录位置"
    return
  fi

  chmod -R 600 "$SSH_SERVER_PRIVATE_KEY"

  # 读取服务器列表文件
  i=0
  echo "密码修改中..."
  while read -r server; do
    ((i++))
    ip=$(echo "$server" | cut -d',' -f1)
    port=$(echo "$server" | cut -d',' -f2)
    pwd=$(echo "$server" | cut -d',' -f3)

    echo "正在修改第${i}行，ip => ${ip}"

    if [ -z "$ip" ] || [ -z "$port" ] || [ -z "$pwd" ] ; then
      echo "解析格式异常"
      continue
    fi

    # 修改密码
    ssh -n -o StrictHostKeyChecking=no -p"$port" -i "$SSH_SERVER_PRIVATE_KEY" root@"$ip"  "echo "root:$pwd" | chpasswd"
    if [ $? -ne 0 ]; then
        echo "命令修改异常"
    fi
  done < "$SERVER_LIST_PWD"
  echo "所有服务器的密码已更新完成"
  return
}

function batch_run_cmd() {
  if [ ! -e  "$SSH_SERVER_PRIVATE_KEY" ] || [ ! -e  "$SERVER_LIST_IP" ] ; then
    echo "请先确保 id_rsa.server、server_list_ip.csv 这2个文件全在当前脚本目录位置"
    return
  fi

  chmod -R 600 "$SSH_SERVER_PRIVATE_KEY"

  read -r -p "请输入要执行的命令: " cmd

   # 读取服务器列表文件
  i=0
  echo "命令执行中..."
  while read -r server; do
    ((i++))
    ip=$(echo "$server" | cut -d',' -f1)
    port=$(echo "$server" | cut -d',' -f2)

    echo "正在执行第${i}行，ip => ${ip}"

    if [ -z "$ip" ] || [ -z "$port" ] ; then
      echo "解析格式异常"
      continue
    fi

    # 执行
    ssh -n -o StrictHostKeyChecking=no -p"$port" -i "$SSH_SERVER_PRIVATE_KEY" root@"$ip"  "$cmd"
    if [ $? -ne 0 ]; then
        echo "命令执行异常"
    fi
  done < "$SERVER_LIST_IP"
  echo "所有服务器的命令已执行完成"
  return
}

function batch_osmonitor_client() {
  if [ ! -e  "${SSH_SERVER_PRIVATE_KEY}" ] || [ ! -e  "${SERVER_LIST_OSMONITOR_CLIENT}" ] ; then
    echo "请先确保 id_rsa.server、server_list_osmonitor_cli.csv 这2个文件在当前脚本目录位置"
    return
  fi
  chmod -R 600 "${SSH_SERVER_PRIVATE_KEY}"

    # 读取服务器列表文件
  i=0
  echo "osmonitor-client服务操作中..."
  while read -r server; do
    ((i++))
    if [ -z "$server" ]; then
      continue
    fi
    ip=$(echo "$server" | cut -d',' -f1)
    port=$(echo "$server" | cut -d',' -f2)
    name=$(echo "$server" | cut -d',' -f3)
    secret=$(echo "$server" | cut -d',' -f4)
    download_url=$(echo "$server" | cut -d',' -f5)
    server_url=$(echo "$server" | cut -d',' -f6)
    proc_names=$(echo "$server" | cut -d',' -f7)
    proc_names=(${proc_names//_/,})

    echo "正在操作第${i}行，worker => ${name}"

    if [ -z "$ip" ] || [ -z "$port" ] || [ -z "$download_url" ] || [ -z "$secret" ] || [ -z "$name" ] || [ -z "$server_url" ] || [ -z "$proc_names" ] ; then
      echo "解析格式异常"
      continue
    fi

    cmd_install="curl -sSf -L ${SHELL_BASE_URL}/osmonitor/osmonitor_client_install.sh |sudo bash -s -- ${name} ${secret} ${download_url} ${server_url} ${proc_names}"
    cmd_uninstall="(if [ -e  /lib/systemd/system/osmonitor-client.service ]; then systemctl disable osmonitor-client.service && systemctl stop osmonitor-client.service && rm -f /lib/systemd/system/osmonitor-client.service; fi; if [ -e  /root/osmonitor/ ]; then rm -rf /root/osmonitor/; fi;) && echo 卸载完毕;"
    cmd=""
    case "$1" in
      "install")
          cmd=${cmd_install}
          ;;
      "uninstall")
          cmd=${cmd_uninstall}
          ;;
      *)
          echo "osmonitor-cli指令操作异常"
          exit 1
          ;;
    esac

    # 服务
    ssh -n -o StrictHostKeyChecking=no -p"$port" -i "$SSH_SERVER_PRIVATE_KEY" root@"$ip" "${cmd}"
    if [ $? -ne 0 ]; then
        echo "命令执行异常"
    fi
  done < "${SERVER_LIST_OSMONITOR_CLIENT}"
  echo "所有服务器操作完毕"
  return
}

function batch_aleo() {
  if [ ! -e  "${SSH_SERVER_PRIVATE_KEY}" ] || [ ! -e  "${SERVER_LIST_ALEO}" ] ; then
    echo "请先确保 id_rsa.server、server_list_aleo.csv 这2个文件在当前脚本目录位置"
    return
  fi

  chmod -R 600 "${SSH_SERVER_PRIVATE_KEY}"

  # 读取服务器列表文件
  i=0
  echo "aleo服务操作中..."
  while read -r server; do
    ((i++))
    if [ -z "$server" ]; then
      continue
    fi
    ip=$(echo "$server" | cut -d',' -f1)
    port=$(echo "$server" | cut -d',' -f2)
    download_url=$(echo "$server" | cut -d',' -f3)
    project=$(echo "$server" | cut -d',' -f4)
    accountname=$(echo "$server" | cut -d',' -f5)
    workername=$(echo "$server" | cut -d',' -f6)

    echo "正在操作第${i}行，worker => ${workername}"

    if [ -z "$ip" ] || [ -z "$port" ] || [ -z "$download_url" ] || [ -z "$project" ] || [ -z "$accountname" ] || [ -z "$workername" ] ; then
      echo "解析格式异常"
      continue
    fi

    cmd_install="curl -sSf -L ${SHELL_BASE_URL}/aleo/aleo_install.sh |sudo bash -s -- ${download_url} ${project} ${accountname} ${workername}"
    cmd_uninstall="(if [ -e  /lib/systemd/system/aleo-miner-${project}.service ]; then systemctl disable aleo-miner-${project} && systemctl stop aleo-miner-${project} && rm -f /lib/systemd/system/aleo-miner-${project}.service; fi; if [ -d  /root/aleo/${project}/ ]; then rm -rf /root/aleo/${project}/; fi;) && echo 卸载完毕;"
    cmd=""
    case "$1" in
      "install")
          cmd=${cmd_install}
          ;;
      "uninstall")
          cmd=${cmd_uninstall}
          ;;
      *)
          echo "aleo指令操作异常"
          exit 1
          ;;
    esac

    # 服务
    ssh -n -o StrictHostKeyChecking=no -p"$port" -i "$SSH_SERVER_PRIVATE_KEY" root@"$ip" "${cmd}"
    if [ $? -ne 0 ]; then
        echo "命令执行异常"
    fi
  done < "${SERVER_LIST_ALEO}"
  echo "所有服务器操作完毕"
  return
}
# 执行菜单
function auto_menu() {
  case $1 in
  1) ssl_gen_key ;;
  2) ssh_gen_key ;;
  3) batch_ssh_update_key ;;
  4) batch_ssh_update_pwd ;;
  5) batch_run_cmd ;;
  6) batch_osmonitor_client install;;
  7) batch_osmonitor_client uninstall;;
  8) batch_aleo install ;;
  9) batch_aleo uninstall ;;
  *) main_menu ;;
  esac
}

# 主菜单
function main_menu() {
    while true; do
        clear
        echo "退出脚本，请按键盘ctrl c退出即可"
        echo "请选择要执行的操作:"
        echo "1. 新建ssl自有证书(cert.key和cert.pem)"
        echo "2. 新建ssh的rsa密钥"
        echo "3. 批量更新各服务器公钥"
        echo "4. 批量修改各服务器密码"
        echo "5. 批量执行自定义命令"
        echo "6. 批量安装osmonitor-client"
        echo "7. 批量卸载osmonitor-client"
        echo "8. 批量安装aleo服务"
        echo "9. 批量卸载aleo服务"
        read -r -p "请输入选项（1-9）: " OPTION

        auto_menu "$OPTION"

        echo "按任意键返回主菜单..."
        read -r -n 1
    done
}


# 根据输入的参数先自动执行，若参数不符合要求，再显示主菜单，该方式主要用于方便定时任务调用
auto_menu "$1"
