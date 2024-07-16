# shell-batch-tools
简易运维脚本，方便非专业运维人员批量操作多台linux设备  
该脚本在ubuntu 22.04标准服务器版中运行通过

## 当前支持功能
1. 新建ssl自有证书(cert.key和cert.pem)
2. 新建ssh的rsa密钥
3. 批量更新各服务器公钥
4. 批量修改各服务器密码
5. 批量执行自定义命令
6. 批量安装aleo服务
7. 批量卸载aleo服务
8. 批量重启aleo服务
9. 批量停止aleo服务
10. 批量配置定时重启aleo任务（每8小时）
11. 批量删除定时重启aleo任务"

## 使用说明
* 该脚本需要root账户中操作
* 批量操作设备，涉及到ssh密钥，需要将密钥文件更名为`id_rsa.server`并放在和`tools.sh`同一个目录
* csv文件使用时，需要去掉`.tpl`后缀

### server_list_ip.csv配置规则
ip,ssh端口号  
例如：
```csv
192.168.1.2,22
```

### server_list_pwd.csv配置规则
ip,ssh端口号,新密码  
例如：  
```csv
192.168.1.2,22,new_password
```

### server_list_aleo.csv配置规则
ip,ssh端口号,下载根地址,池子名称,池子账户,worker编号,gpu或cpu模式  
例如：  
```csv
192.168.1.2,22,http://172.16.1.2,apool,apool_account_name,apool_worker_name,gpu/cpu
```
说明：下载根地址，是指程序所在http服务器的位置，并且服务器程序名称必须按照规则：`aleo-miner-池子名称`来命名，例如：`aleo-miner-apool` 

## 脚本使用说明
```shell
# 启动脚本
./tools
```
关于脚本的更新，是指更新`tools.sh`这个脚本。默认脚本是在github托管，因此涉及到的脚本更新、脚本url执行等，默认都是用的github的url地址。如果想自行托管，则需要在`.env`文件中修改`SHELL_BASE_URL`值
