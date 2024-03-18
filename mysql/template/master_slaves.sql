{% if master_ip in ansible_all_ipv4_addresses %}
    {% if '8.0' in mysql_package %}
        create user {{mysql_repl_user}}@'%' identified with 'mysql_native_password' by '{{mysql_repl_password}}';
        grant replication slave,replication client on *.* to {{mysql_repl_user}}@'%';
    {% else %}
        create user {{mysql_repl_user}}@'%' identified by '{{mysql_repl_password}}';
        grant replication slave,replication client on *.* to {{mysql_repl_user}}@'%';
    {% endif %}

    flush privileges;

{% else %}
select sleep(17);

set @@global.read_only=on;

change master to
    master_host='{{master_ip}}',
    master_port={{mysql_port}},
    master_user='{{mysql_repl_user}}',
    master_password='{{mysql_repl_password}}',
    master_auto_position=1;

start slave;
{% endif %}
