#!/bin/bash
export PATH=$PATH:/usr/local/mysql/bin:/usr/local/xtrabackup/bin
rm -rf /usr/local/mysql/data/*
tar -izxvf /home/$1 -C /usr/local/mysql/data
sed 's/innodb_fast_checksum/# \0/g' /usr/local/mysql/data/backup-my.cnf
sed 's/innodb_page_size/# \0/g' /usr/local/mysql/data/backup-my.cnf
sed 's/innodb_log_block_size/# \0/g' /usr/local/mysql/data/backup-my.cnf
innobackupex --defaults-file=/usr/local/mysql/data/backup-my.cnf --apply-log /usr/local/mysql/data
chown -R mysql.mysql /usr/local/mysql/data
