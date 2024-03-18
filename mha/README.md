## mha安装

**MHA是在mysql主从复制环境的基础上加的一套高可用软件、这套软件逻辑上又可以分成两个组件manager和node；其中manager负责监控master库是否存活，一旦master有问题就开大招做主从切换、切换中的一些脏活累活基本都由node来完；** 相关链接：https://www.cnblogs.com/gomysql/p/3675429.html

### 环境规划

**130、131、132三个实例组成一个mysql复制环境、其中130是master**

| 主机名    | ip地址         | 操作系统版本 | mysql角色 | mha角色 | vip            |
| --------- | -------------- | ------------ | --------- | ------- | -------------- |
| mhamaster | 192.168.29.130 | centos-7.9   | master    | node    | 192.168.29.100 |
| mhaslave1 | 192.168.29.131 | centos-7.9   | slave     | node    |                |
| mhaslave2 | 192.168.29.132 | centos-7.9   | slave     | manager |                |

### 配置mha的一些前置备件

**1、已经规范的安装配置了mysql复制环境、可以参考[mysql主从复制](#mysql主从复制)**

**2、各个主机之间需要配置ssh信任，需要安装sshpass,可以提前手动安装**

```
yum install sshpass --nogpgcheck -y
```

**3、mha需要使用gcc进行编译、需要安装gcc、gcc-c++和perl-DBD-MySQL ，需要手动配置基础yum源和epel源，可以提前手动安装**

```
yum install epel-release --nogpgcheck -y
# 可选，会自动安装
yum install gcc gcc-c++
yum install -y perl-DBD-MySQL \
perl-Config-Tiny \
perl-Log-Dispatch \
perl-Parallel-ForkManager \
perl-ExtUtils-CBuilder \
perl-ExtUtils-MakeMaker \
perl-CPAN
```

### mha安装

---

1. **配置mha的相关信息**

   mha是一个独立的项目，没有引用外部mysql的安装配置文件，mha的所有配置都记录在了vars/var_mha.yaml这个配置文件中，配置多了点，请耐心参考注释修改变量。
2. **生成hosts文件**

   执行脚本，当前目录下会自动生成hosts文件

```
ansible-playbook generate_hosts.yaml
```

3. ### 安装配置mha


   ```
   ansible-playbook -i hosts install_mha.yaml
   # 或者分开安装
   ansible-playbook -i hosts install_mha.yaml --tags install_nodes
   ansible-playbook -i hosts install_mha.yaml --tags install_manager
   ```
4. ### 验证是否成功完成

   ---

   **1、验证master主机是否成功的绑定了vip**


   ```
   ip a
   ```

   ens33:0绑上了192.168.29.100 这个vip、说明vip绑定成功了

   ---

   **2、验证mha-manager是否正常启动**

   ```
   masterha_check_status --conf=/etc/masterha/app1.cnf
   ```

   ---

   **3、检查ssh互信是否配置正确**

   ```
   masterha_check_ssh -conf=/etc/masterha/app1.cnf
   ```

   最后一行 `All SSH connection tests passed successfully.`说明ssh信任是配置好了的

   ---

   **4、检查mysql 复制是否配置正确**

   ```
   masterha_check_repl -conf=/etc/masterha/app1.cnf
   ```

---

### mha故障恢复

mysql的master节点发生故障的时，mha会把自动切换把其中一个slave节点提升为master节点，而故障的mysql的master节点重新启动后，并不会自动的变成集群的slave节点，需要手动配置。

`add_recover_slave.yaml`脚本可以把恢复后的节点作为slave节点，添加到集群中。

1. 修改 `vars/var_mha.yaml`中的 `master_ip`，根据实际情况，设置新的master节点的ip
2. 执行脚本后，slave_ip节点会成为 `master_ip`节点的slave节点

```
ansible-playbook -i hosts add_recover_slave.yaml -e slave_ip="192.168.29.130"
```

3. 登录mha_manager服务上，检查集群复制配置是否正常

```
masterha_check_repl -conf=/etc/masterha/app1.cnf
```

4. 主从复制的节点都正常后，就可以重新启动mha_manager

```
/usr/local/masterha/start_mha.sh
```

5. 检查mha启动是否正常

```
masterha_check_status --conf=/etc/masterha/app1.cnf
```

---

### mha卸载

卸载mha

```
ansible-playbook -i hosts uninstall_mha.yaml
```

mha_manager和mha_nodes分开卸载

卸载mha_manager

```
ansible-playbook -i hosts uninstall_mha.yaml --tags uninstall_manager
```

卸载mha_nodes

```
ansible-playbook -i hosts uninstall_mha.yaml --tags uninstall_nodes
```

---
