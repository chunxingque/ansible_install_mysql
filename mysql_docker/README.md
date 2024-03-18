## mysql部署

使用docker部署mysql


### mysql单主机部署

**1.修改通用部署配置文件：vars/common_config.yaml**

按照实际需要修改配置

**2.修改ansible的hosts文件**

例如：安装到多台主机，并且 一台主机仅安装一个mysql

```一台主机上装一个mysql
[mysql_server]
mysql1 ansible_host="192.168.15.10" mysql_name="mysql"  mysql_port=3306
mysql2 ansible_host="192.168.15.11" mysql_name="mysql"  mysql_port=3306
mysql3 ansible_host="192.168.15.12" mysql_name="mysql"  mysql_port=3306
```


例如：一台主机安装多个mysql

```一台主机上装一个mysql
[mysql_server]
mysql1 ansible_host="192.168.15.10" mysql_name="mysql_3306"  mysql_port=3306
mysql2 ansible_host="192.168.15.10" mysql_name="mysql_3307"  mysql_port=3307
mysql3 ansible_host="192.168.15.10" mysql_name="mysql_3308"  mysql_port=3308
```

注意：同台主机的mysql_name和mysql_port不能相同

3.执行安装脚本

```
ansible-playbook -i hosts install_single_mysql.yaml
```

---



### mysql卸载

1.参考mysql安装，修改ansible的hosts文件

2.执行卸载脚本

```
ansible-playbook -i hosts uninstall_mysql.yaml
```
