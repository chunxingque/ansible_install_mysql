
## mysql安装

### 要求

1. 管理主机需要安装ansible环境，并配置ssh免密登录
2. 支持内网主机离线安装
3. 仅支持rhel的linux系统

注意事项

* 目前mysql8需要glibc 2.28，而centos7的glibc过低，不建议使用centos7安装mysql8，建议使用rhel8以上安装mysql8

### mysql依赖（可选）

安装mysql依赖，这是可选步骤，一些linux系统不需要安装，不影响mysql运行，例如: centos7.9。这个为了支持内网主机离线安装，不依赖yum，特意把安装mysql依赖这个步骤单独出来，作为一个可选安装步骤。

如果服务器正常访问到yum源，可以在每个安装脚本中取消注释，安装mysql时，顺便安装这些依赖

```
    # - name: install mysql dependents 
    #   import_tasks: common/install_mysql_dependents.yaml
```

也可以独立执行以下脚本进行安装

```
ansible-playbook -i hosts install_mysql_dependents.yaml
```

可以手动安装

```
yum install libaio-devel
yum install numactl-devel
yum install perl-Data-Dumper
```

---

### 下载MySQL

把MySQL的安装包要下载到**package**目录下，仅支持 `tar.gz`和 `tar.xz`格式的压缩包

mysql版本选择页面：https://downloads.mysql.com/archives/community/

mysql5.7： https://cdn.mysql.com/archives/mysql-5.7/mysql-5.7.43-linux-glibc2.12-x86_64.tar.gz

```
 cd package
 wget https://cdn.mysql.com/archives/mysql-5.7/mysql-5.7.43-linux-glibc2.12-x86_64.tar.gz
```

注意：下载压缩包时，需要根据服务器的glibc的版本选，例如：8.2.0有glibc 2.17和glibc 2.28的压缩包,centos7选择glibc 2.17的，rhel8和rhel9的选择glibc 2.28，具体需要看glibc的版本，查看glibc版本命令如下：

```
strings /lib64/libc.so.6 | grep "^GLIBC_"
```

---

### mysql单实例安装

* 支持版本： mysql5.6.x、mysql5.7.x、mysql8.x.x
* 测试版本：mysql-5.7.43、mysql-8.0.35、mysql-8.2.0
* 支持系统：rhel7.x、rhel8.x、rhel9.x
* 测试系统：rhel7.x、rhel9.x
* 技术：基于GTID的主从复制

1. 修改hosts

```
[mysql_server]
192.168.15.209 ansible_user=root
```

3. 根据注释，修改vars/common_config.yaml通用配置文件
4. 执行自动化安装脚本

```bash
ansible-playbook -i hosts install_single_mysql.yaml
```

注意：解压时，可能会卡主，可以直接停掉，然后重新执行脚本

5. 测试MySQL是否安装成功

```bash
mysql -uroot -p 
```

---

### mysql单实例版本升级

前言： 此版本升级并不会去执行 `mysql_upgrade`脚本

**1):修改upgrad_single_mysql.yaml文件的hosts 变量为你要升级的目标主机**

```
[mysql_server]
192.168.15.209 ansible_user=root
```

---

**2):执行升级程序**

```
ansible-playbook -i hosts upgrad_single_mysql.yaml
```

**3):执行mysql_upgrade命令（非必须）**

5.7.x及以下版本升级后，还需要执行 `mysql_upgrade`命令，升级系统的表；而8.x.x以上版本则不需要执行此命令

```
mysql_upgrade -uroot -p
```

---

**3):查看升级是否成功**

1、看/usr/local/下的变化

**升级前**

```
drwxr-xr-x   9 mysql mysql 129 6月  18 14:46 mysql-5.7.21-linux-glibc2.12-x86_64
lrwxrwxrwx   1 root  root   35 6月  18 14:53 mysql -> mysql-5.7.21-linux-glibc2.12-x86_64
```

**升级后**

```
lrwxrwxrwx   1 mysql mysql  46 6月  18 15:30 mysql -> /usr/local/mysql-5.7.22-linux-glibc2.12-x86_64
drwxr-xr-x   9 mysql mysql 129 6月  18 14:46 mysql-5.7.21-linux-glibc2.12-x86_64
drwxr-xr-x   9 mysql mysql 129 6月  18 15:30 mysql-5.7.22-linux-glibc2.12-x86_64
lrwxrwxrwx   1 root  root   35 6月  18 14:53 mysql.backup.20180618 -> mysql-5.7.21-linux-glibc2.12-x86_64
```

---

2、连接进数据库进行检查

```
mysql -uroot -pxxxxxx
```

```
mysql: [Warning] Using a password on the command line interface can be insecure.
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 3
Server version: 5.7.22-log MySQL Community Server (GPL)

Copyright (c) 2000, 2018, Oracle and/or its affiliates. All rights reserved.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql>select @@version;
+------------+
| @@version  |
+------------+
| 5.7.22-log |
+------------+
1 row in set (0.00 sec)
```

---

### 卸载mysql

慎重，执行卸载的脚本，会删除mysql的程序、数据和配置文件等

```
ansible-playbook -i hosts uninstall.yaml
```

---

### 主从复制-GTID

* 支持版本： mysql5.7.x、mysql8.x.x
* 测试版本：mysql-5.7.43、mysql-8.0.35
* 技术：基于GTID的主从复制

假设我们要在**10.186.19.15，10.186.19.16，10.186.19.17** 两台主机上建设一个一主两从的主从复制环境，其中10.186.19.15为主库

**1):修改通用配置文件：vars/common_config.yaml**

主要修改mysql_package的名称，还有数据库的账号密码，其他默认即可

**2) 修改主从复制配置文件：install_master_slaves.yaml**

1.修改master主从复制的账号和密码

2.确认那个ip是主，那些ip是slave

```
   master_ip: 10.186.19.15
   slave_ips:
     - 10.186.19.16
     - 10.186.19.17
```

**3):生成hosts文件**

执行脚本，当前目录下会自动生成hosts文件

```
ansible-playbook generate_hosts.yaml --tags master_slaves
```

hosts内容大致如下：

```
[mysql_server]
10.186.19.15 ansible_user=root
10.186.19.16 ansible_user=root
10.186.19.17 ansible_user=root
```

---

   **4):执行自动化安装**

```bash
ansible-playbook -i hosts install_master_slaves.yaml 
```

   **5):检查主从复制环境是否配置完成**

```
   mysql -uroot -p
   show slave status \G
```

   输出如下

```
   *************************** 1. row ***************************
                  Slave_IO_State: Waiting for master to send event
                     Master_Host: 10.186.19.15
                     Master_User: rple
                     Master_Port: 3306
                   Connect_Retry: 60
                 Master_Log_File: mysql-bin.000002
             Read_Master_Log_Pos: 595
                  Relay_Log_File: actionsky16-relay-bin.000002
                   Relay_Log_Pos: 800
           Relay_Master_Log_File: mysql-bin.000002
                Slave_IO_Running: Yes
               Slave_SQL_Running: Yes
               ... ... ... ... ... ... ... ... 
              Retrieved_Gtid_Set: 8b5ac555-37ec-11e8-b50e-5a3fdb1cf647:1-2
               Executed_Gtid_Set: 8b5ac555-37ec-11e8-b50e-5a3fdb1cf647:1-2
                   Auto_Position: 1
            Replicate_Rewrite_DB: 
                    Channel_Name: 
              Master_TLS_Version:
```

   两个Yes 说明说明主从复制环境成功配置了

---

### mysql多源复制

假设我们要在**10.186.19.15，10.186.19.16，10.186.19.17**这三台机器上搭建两主1从的多源复制环境、其中15，16两机器上的数据向17同步

---

**1):增加主机信息到/etc/ansible/hosts**

向/etc/ansible/hosts文件中增加如下内容

```
[repl]
replmaster15 ansible_host=10.186.19.15
replslave16 ansible_host=10.186.19.16
replslave17 ansible_host=10.186.19.17
```

---

**2):进入mysql功能目录**

```bash
cd /usr/local/mysqltools/deploy/ansible

cd mysql  #进入mysql功能目录
```

---

**3):指定install_multi_source_replication.yaml中的目标主机**

假设我要在repl主机组上安装mysql复制环境那么install_multi_source_replication.yaml文件中的hosts变量应该设置为repl

```yaml
---
 - hosts: repl
```

修改vars/multi_source_replication.yaml 告诉mysqltools那些ip是主那个ip是slave

```
#master_ips 定义多个master主机ip组成的列表
master_ips:
 - '10.186.19.15'
 - '10.186.19.16'

#定义slave的ip
slave_ip: '10.186.19.17'
```

---

**4):执行自动化安装**

```bash
ansible-playbook install_multi_source_replication.yaml 
```

输出省略

```

```

---

**5):检测多源复制环境是否安装成功**

```
mysql -uroot -pmtls0352
show slave status \G
```

输出如下

```
*************************** 1. row ***************************
               Slave_IO_State: Waiting for master to send event
                  Master_Host: 10.186.19.15
                  Master_User: rple_user
                  Master_Port: 3306
                Connect_Retry: 60
              Master_Log_File: mysql-bin.000002
          Read_Master_Log_Pos: 150
               Relay_Log_File: actionsky17-relay-bin-master1.000002
                Relay_Log_Pos: 355
        Relay_Master_Log_File: mysql-bin.000002
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
*************************** 2. row ***************************
               Slave_IO_State: Waiting for master to send event
                  Master_Host: 10.186.19.16
                  Master_User: rple_user
                  Master_Port: 3306
                Connect_Retry: 60
              Master_Log_File: mysql-bin.000002
          Read_Master_Log_Pos: 150
               Relay_Log_File: actionsky17-relay-bin-master2.000002
                Relay_Log_Pos: 355
        Relay_Master_Log_File: mysql-bin.000002
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
```

两个通道都是双Yes、多源监制环境成了哦！

---

### mysql组复制-MGR

* 支持版本：mysql5.7.x、mysql8.x.x
* 测试版本：mysql-5.7.43、mysql-8.0.35
* 支持系统：rhel7.x、rhel8.x、rhel9.x
* 测试系统：rhel7.x、rhel9.x
* MGR模式：单主和多主

假设我们要在 192.168.15.209，192.168.15.220，192.168.15.221 这三台机器上搭建一个group replication 环境

**1):修改通用配置文件：vars/common_config.yaml**

根据注释修改通用配置

**2):修改组复制配置：install_group_replication.yaml**

修改组名，组名用的是uuid，可以用 `uuidgen`命令生成

```
# 组名uuid: aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa
group_name_uuid: "b7fbede1-2827-43a4-92f1-bd288607b8f9"
```

修改集群

```
# 组复制集群
mysql_cluster:
  - name: mysql-node1
    ip: '192.168.15.209'
  - name: mysql-node2
    ip: '192.168.15.220'
  - name: mysql-node3
    ip: '192.168.15.221'
```

name会作为主机的主机名，也会配置到/etc/hosts上

**3): 生成hosts**

执行该脚本会在当前目录自动生成hosts文件

```
ansible-playbook generate_hosts.yaml --tags group_replication
```

生成内容如下：

```
[mysql_server]
192.168.15.209 ansible_user=root node_name="mysql-node1"
192.168.15.220 ansible_user=root node_name="mysql-node2"
192.168.15.221 ansible_user=root node_name="mysql-node3"
```

**4):执行自动化安装**

```bash
ansible-playbook -i hosts install_group_replication.yaml 
```

**5):检查group replication集群是否安装成功**

```bash
mysql -uroot -p
select * from performance_schema.replication_group_members;
```

输出如下

```
+---------------------------+--------------------------------------+-------------+-------------+--------------+
| CHANNEL_NAME              | MEMBER_ID                            | MEMBER_HOST | MEMBER_PORT | MEMBER_STATE |
+---------------------------+--------------------------------------+-------------+-------------+--------------+
| group_replication_applier | 08de362c-3802-11e8-9e65-5a3fdb1cf647 | actionsky15 |        3306 | ONLINE       |
| group_replication_applier | ef7f3b61-3801-11e8-886d-9a17854b700d | actionsky17 |        3306 | ONLINE       |
| group_replication_applier | f1649143-3801-11e8-8fd3-5a1f0f06c50d | actionsky16 |        3306 | ONLINE       |
+---------------------------+--------------------------------------+-------------+-------------+--------------+
3 rows in set (0.00 sec)
```

三个都是online说明group replication 配置成功了哦

### InnoDB集群

* mysql支持版本：mysql8.x.x
* 支持系统：rhel8.x、rhel9.x
* mysql测试版本：mysql-8.2.0
* 测试系统：rhel9.x

#### mysql资源下载

**mysql-shell下载**

mysql-shell下载地址：https://downloads.mysql.com/archives/shell/

mysql-router下载地址：https://downloads.mysql.com/archives/router/

```
cd package
wget https://downloads.mysql.com/archives/get/p/43/file/mysql-shell-8.2.0-linux-glibc2.28-x86-64bit.tar.gz
wget https://downloads.mysql.com/archives/get/p/41/file/mysql-router-8.2.0-linux-glibc2.28-x86_64.tar.xz
```

注意：mysql-shell、mysql-router和mysql-server的版本需要一致

#### 配置文件修改

**1):修改通用配置文件：vars/common_config.yaml**

主要修改mysql_package的名称，还有数据库的账号密码，其他默认即可

**2) 修改innode集群配置文件：innodb_cluster.yaml**

1.修改mysql_shell和mysql_router的压缩包名

2.修改innodb集群

```
mysql_cluster:
  - name: mysql-node1
    ip: '192.168.15.15'
  - name: mysql-node2
    ip: '192.168.15.16'
  - name: mysql-node3
    ip: '192.168.15.17'
```

3.指定mysql_router服务器

```
mysql_router_server:
  - '192.168.15.17'
```

* 加这个配置，可以根据实际需求，指定部署到特定的服务器，而不是部署到集群上的所有服务器。
* 建议选择集群中的服务器，因为查询集群路由时，路由的名称使用的是hostname，因此mysql_router需要主机配置好hostname和hosts,比较麻烦，如果未使用集群中的服务器，请手动手动配置集群和mysqlrouter的hostname和hosts。

4.其他默认即可

#### **生成hosts文件**

执行脚本，当前目录下会自动生成hosts文件

```
ansible-playbook generate_hosts.yaml --tags innodb_cluster
```

hosts内容大致如下：

```
[mysql_server]
10.186.19.15 ansible_user=root node_name="mysql-node1"
10.186.19.16 ansible_user=root node_name="mysql-node2"
10.186.19.17 ansible_user=root node_name="mysql-node3"

[mysql_router]
192.168.88.224 ansible_user=root

```

---

#### mysql和mysql-shell安装

安装mysql单实例

```
ansible-playbook -i hosts install_innode_cluster.yaml --tags install_mysql
```

安装mysql_shell

```
ansible-playbook -i hosts install_innode_cluster.yaml --tags install_mysql_shell
```

---

#### 集群创建

可以先手动检查各个节点的配置（可选）

```
/usr/local/mysql-shell/bin/mysqlsh root@mysql-node1 -p'dbpasswd' --execute "dba.checkInstanceConfiguration();"
```

创建集群，并加入节点

```
ansible-playbook -i hosts install_innode_cluster.yaml --tags init_cluster
```

检查集群

---

#### mysql-router 安装

安装mysql_router

```
ansible-playbook -i hosts install_innode_cluster.yaml --tags install_mysql_router
```

进入mysqlsh环境，查看路由

```
dba.getCluster().listRouters();
```

---

#### 添加新节点

**1.修改配置**

修改innode集群配置文件：innodb_cluster.yaml

```
# innodb集群
mysql_cluster:
  ......
  - name: mysql-node4
    ip: '192.168.15.18'

# 添加新的innodb节点
add_new_nodes:
  enabled: true
  nodes:
  - name: mysql-node4
    ip: '192.168.15.18'
```

在mysql_cluster字段中添加新的节点，然后复制新的节点配置到add_new_nodes.nodes字段中,add_new_nodes.enabled设置为true即可

**2.生成新的hosts文件**

执行脚本，生成新的hosts文件

```
ansible-playbook generate_hosts.yaml --tags innodb_cluster
```

或者手动修改

```
[mysql_server]
192.168.15.18 ansible_user=root node_name="mysql-node4"
```

**3.安装mysql**

```
ansible-playbook -i hosts install_innode_cluster.yaml --tags install_mysql
```

**4.安装mysql_shell**

```
ansible-playbook -i hosts install_innode_cluster.yaml --tags install_mysql_shell
```

**5.集群中添加新节点**

使用脚本自动添加

```
ansible-playbook -i hosts install_innode_cluster.yaml --tags add_nodes
```

手动添加节点

1）使用mysqlsh连接到master节点上

```
mysqlsh root@mysql-node1 -pmtls0352
```

2）添加节点

```
var cluster = dba.getCluster();
cluster.status();
# 加入新的集群节点，过程中通常选择 Clone 模式来复制主节点的数据
cluster.addInstance('root@mysql-node4:3306');
```
