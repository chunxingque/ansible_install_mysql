grant all privileges on *.* to {{mysql_mha_user}}@'%' identified by '{{ mysql_mha_password }}';
flush privileges;