{% if 'mysql-5.6' in mysql_package %}
set sql_log_bin=0;
    update mysql.user set password=password('{{ mysql_root_password }}') where user='root';

    {% if mysql_backup_user.enable -%}
    create user {{mysql_backup_user.user}}@'{{mysql_backup_user.host}}' identified by '{{mysql_backup_user.password}}';

    grant reload,lock tables on *.* to {{mysql_backup_user.user}}@'{{mysql_backup_user.host}}';
    grant replication client on *.* to {{mysql_backup_user.user}}@'{{mysql_backup_user.host}}';
    grant create tablespace  on *.* to {{mysql_backup_user.user}}@'{{mysql_backup_user.host}}';
    grant process            on *.* to {{mysql_backup_user.user}}@'{{mysql_backup_user.host}}';
    grant super              on *.* to {{mysql_backup_user.user}}@'{{mysql_backup_user.host}}';
    grant create,insert,select      on percona_schema.xtrabackup_history to {{mysql_backup_user.user}}@'{{mysql_backup_user.host}}';
    
    grant create,insert,drop,update               on mysql.backup_progress to {{mysql_backup_user.user}}@'{{mysql_backup_user.host}}';
    grant create,insert,drop,update,select,alter  on mysql.backup_history  to {{mysql_backup_user.user}}@'{{mysql_backup_user.host}}';
    {% endif %}

    flush privileges;

set sql_log_bin=1;

{% else %}

set sql_log_bin=0;
    alter user root@'localhost' identified by '{{ mysql_root_password }}' ;

    {% if mysql_remote_user.enable -%}
    create user {{mysql_remote_user.user}}@'{{mysql_remote_user.host}}' identified by '{{mysql_remote_user.password}}';
    GRANT ALL PRIVILEGES ON *.* TO {{mysql_remote_user.user}}@'{{mysql_remote_user.host}}' WITH GRANT OPTION;
    {% endif %}

    {% if mysql_backup_user.enable -%}
    create user {{mysql_backup_user.user}}@'{{mysql_backup_user.host}}' identified by '{{mysql_backup_user.password}}';
    
    grant reload,lock tables on *.* to {{mysql_backup_user.user}}@'{{mysql_backup_user.host}}';
    grant replication client on *.* to {{mysql_backup_user.user}}@'{{mysql_backup_user.host}}';
    grant create tablespace  on *.* to {{mysql_backup_user.user}}@'{{mysql_backup_user.host}}';
    grant process            on *.* to {{mysql_backup_user.user}}@'{{mysql_backup_user.host}}';
    grant super              on *.* to {{mysql_backup_user.user}}@'{{mysql_backup_user.host}}';
    grant create,insert,select      on percona_schema.xtrabackup_history to {{mysql_backup_user.user}}@'{{mysql_backup_user.host}}';
    
    grant create,insert,drop,update               on mysql.backup_progress to {{mysql_backup_user.user}}@'{{mysql_backup_user.host}}';
    grant create,insert,drop,update,select,alter  on mysql.backup_history  to {{mysql_backup_user.user}}@'{{mysql_backup_user.host}}';
    
    grant select on performance_schema.replication_group_members to {{mysql_backup_user.user}}@'{{mysql_backup_user.host}}';
    {% endif %}

    flush privileges;

set sql_log_bin=1;

{% endif %}

