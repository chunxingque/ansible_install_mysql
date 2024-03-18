set sql_log_bin=0;
create user {{mysql_repl_user}}@'%' identified WITH mysql_native_password by '{{mysql_repl_password}}';
grant replication slave,replication client on *.* to {{mysql_repl_user}}@'%';
flush privileges;
reset master;
set sql_log_bin=1;

change master to 
    master_user='{{mysql_repl_user}}',
    master_password='{{mysql_repl_password}}'
    for channel 'group_replication_recovery';

install plugin group_replication soname 'group_replication.so';

{% if ansible_host == mysql_cluster[0]['ip'] %}
set global group_replication_bootstrap_group=on;
start group_replication;
set global group_replication_bootstrap_group=off;
{% else %}
select sleep(15);
start group_replication;
{% endif %}
