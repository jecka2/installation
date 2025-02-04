#!/bin/bash

apt update && apt upgrade -y


# Переменные для настройки сети
IP_ADDRESS="192.168.1.22"   # Статический IP-адрес
NETMASK="24"      # Маска подсети
GATEWAY="192.168.0.1"        # Шлюз по умолчанию
DNS_SERVERS="192.168.1.147,192.168.1.146" # DNS-серверы

#Поиск текущего сетевого интерфейса
INT=$(ip link show | grep '^[0-9]*:' | awk '{print $2}' |grep -v '^lo:$')

# Файл конфигурации сетевого интерфейса
INTERFACE_FILE="/etc/netplan/01-netcfg.yaml"

# Резервная копия текущего файла конфигурации
sudo cp $INTERFACE_FILE ${INTERFACE_FILE}.bak

# Содержание нового файла конфигурации
cat <<EOF > $INTERFACE_FILE
network:
  version: 2
  renderer: networkd
  ethernets:
    $INT
      dhcp4: no
      addresses: [$IP_ADDRESS/$NETMASK]
      gateway4: $GATEWAY
      nameservers:
        addresses: [$DNS_SERVERS]
EOF

# Применяем изменения
sudo netplan apply


## Установка MySQL Server
apt-get install mysql-server git  -y

# Запуск службы MySQL
systemctl start mysql
 
echo "Укажи имя bin log которое было указано в таблице ранее"
read binlog
echo "Укажи позицию из таблицы котороая была указана ранее"
read pos

# Создание пользователя для репликации
SQL_COMMANDS="
STOP SLAVE;
CHANGE MASTER TO MASTER_HOST='192.168.1.21', MASTER_USER='replication_user', MASTER_PASSWORD='password', MASTER_LOG_FILE='$binlog', MASTER_LOG_POS=$pos, GET_MASTER_PUBLIC_KEY = 1;
START SLAVE;
show replica status\G

# GTID
STOP REPLICA;
CHANGE REPLICATION SOURCE TO SOURCE_HOST='mysql8master', SOURCE_USER='repl', SOURCE_PASSWORD='oTUSlave#2020', SOURCE_AUTO_POSITION = 1, GET_SOURCE_PUBLIC_KEY = 1;
START REPLICA;
"
mysql -u root -e "${SQL_COMMANDS}" 

systemctl stop mysql
cp /tmp/mysqld_slave.cnf  /etc/mysql/mysql.conf.d/mysqld.cnf
systemctl start mysql
