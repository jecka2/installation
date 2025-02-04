#!/bin/bash

apt update && apt upgrade -y


# Переменные для настройки сети
IP_ADDRESS="192.168.1.22"   # Статический IP-адрес
NETMASK="24"      # Маска подсети
GATEWAY="192.168.0.1"        # Шлюз по умолчанию
DNS_SERVERS="192.168.1.147 192.168.1.146" # DNS-серверы

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
 


# Создание пользователя для репликации
SQL_COMMANDS="
CREATE USER 'replication_user'@'%' IDENTIFIED BY 'password';
GRANT REPLICATION SLAVE ON *.* TO 'replication_user'@'%';
FLUSH PRIVILEGES;
"
mysql -u root -e "${SQL_COMMANDS}" 

systemctl stop mysql
cp /tmp/mysqld_main.cnf  /etc/mysql/mysql.conf.d/mysqld.cnf
systemctl start mysql
