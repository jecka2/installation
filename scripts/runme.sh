#!/bin/bash 

echo  "ВВедите имя пользователя для доступа к сервера по ssh:"
read  user
echo  "Введите ip адресс сервера back+masterbd:"
read  back_master
echo "Введите ip адресс сервера back+replbd:"
read  back_repl



cd /tmp
git clone https://github.com/jecka2/installation.git
ssh-copy-id $user@$back_master
ssh-copy-id $user@$back_repl
scp  /tmp/installation/scripts/backmaster.sh $user@$back_master:/tmp/backmaster.sh
scp /tmp/installation/configs/mysqld_main.cnf $user@$back_master:/tmp/mysqld_main.cnf
ssh -t $user@$back_master "sudo bash  /tmp/backmaster.sh"
scp  /tmp/installation/scripts/backrepl.sh $user@$back_repl:/tmp/backrepl.sh
scp /tmp/installation/configs/mysqld_slave.cnf $user@$back_repl:/tmp/mysqld_slave.cnf
ssh -t $user@$back_repl "sudo bash  /tmp/backrepl.sh"
