#!/bin/bash

nohup /usr/local/bin/masterha_manager --conf=/etc/masterha/app1.cnf --ignore_last_failover < /dev/null > /var/log/masterha/app1/manager.log 2>&1 &