# shell-batch-tools

简易运维脚本，方便非专业运维人员批量操作多台 linux 设备  
该脚本在 ubuntu 22.04 标准服务器版中运行通过

## 当前支持功能

1. 新建 ssl 自有证书(cert.key 和 cert.pem)
2. 新建 ssh 的 rsa 密钥
3. 批量更新各服务器公钥
4. 批量修改各服务器密码
5. 批量执行自定义命令
6. 批量安装进程监控
7. 批量卸载进程监控
8. 批量安装 aleo 服务
9. 批量卸载 aleo 服务

## 使用说明

- 该脚本需要 root 账户中操作
- 批量操作设备，涉及到 ssh 密钥，需要将密钥文件更名为`id_rsa.server`并放在和`tools.sh`同一个目录
- csv 文件使用时，需要去掉`.tpl`后缀
- 一些简单命令直接使用`批量执行自定义命令`即可
- 关于`进程监控`监控功能，需要参考我这个项目[osmonitor](https://github.com/bitxx/osmonitor)，先部署一台 osmonitor-server，然后通过该脚本批量部署`osmonitor-client`到需要监控的设备
- 目前 aleo 池子支持 f2pool、oula、6block

### server_list_ip.csv 配置规则

ip,ssh 端口号  
例如：

```csv
192.168.1.2,22
```

### server_list_pwd.csv 配置规则

ip,ssh 端口号,新密码  
例如：

```csv
192.168.1.2,22,new_password
```

### server_list_aleo.csv 配置规则

ip,ssh 端口号,下载根地址,池子名称,池子账户,worker 编号
例如：

```csv
192.168.1.2,22,http://172.16.1.2,oula,oula_account_name,oula_worker_name
```

说明：下载根地址，是指程序所在 http 服务器的位置，并且服务器程序名称必须按照规则：`aleo-miner-池子名称`来命名，例如：`aleo-miner-oula`

### server_list_osmonitor_cli.csv

就是部署 `osmonitor-client 需要的参数`
ip,ssh 端口号,name,secret,download_url,service_url,proc_names

## 脚本使用说明

```shell
# 启动脚本
./tools
```
