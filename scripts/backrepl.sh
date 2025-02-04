#!/bin/bash

apt update && apt upgrade -y


# Директория, в которой находятся файлы
directory="/etc/netplan"

# Переходим в указанную директорию
cd "$directory" || exit 1


# Получаем список всех файлов в этой директории
files=(*)

# Цикл по всем файлам
for file in "${files[@]}"; do
    # Если текущий элемент является файлом
    if [[ -f "$file" ]]; then
        # Формируем новое имя файла
        new_file="${file%.yml}.yml.bak"
            # Переименовываем файл
            mv -n "$file" "$new_file"
       fi
done
# Переменные для настройки сети
IP_ADDRESS="192.168.1.142"   # Статический IP-адрес
NETMASK="24"      # Маска подсети
GATEWAY="192.168.1.1"        # Шлюз по умолчанию
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
      routes:
      - to: default
        via: $GATEWAY
      nameservers:
        addresses: [$DNS_SERVERS]
EOF


# Применяем изменения
#sudo netplan apply
chmod 600 $INTERFACE_FILE


## Установка MySQL Server
apt-get install mysql-server git  -y

# Запуск службы MySQL
systemctl start mysql


SQL_COMMANDS="
CREATE USER 'replication'@'%' IDENTIFIED BY 'password';
GRANT REPLICATION SLAVE ON *.* TO 'replication'@'%';
FLUSH PRIVILEGES;
SHOW MASTER STATUS;
"
mysql -u jecka -h 192.168.1.141 -p123qweASD! -e "${SQL_COMMANDS}"


 
#SQL_COMMANDS="
#CREATE USER 'replication'@'%' IDENTIFIED BY 'password';
#GRANT REPLICATION SLAVE ON *.* TO 'replication'@'%';
#FLUSH PRIVILEGES;
#"


# Получаем информацию о позиции бинлога
MASTER_LOG_FILE=$(mysql -ujecka -h192.168.1.141 -p123qweASD!  -e "SHOW MASTER STATUS\G" | grep File | awk '{print $2}')
MASTER_LOG_POS=$(mysql -ujecka -h192.168.1.141 -p123qweASD! -e "SHOW MASTER STATUS\G" | grep Position | awk '{print $2}')

# Сохраняем данные в файл
echo "Master Log File: ${MASTER_LOG_FILE}" > /tmp/master_info.txt
echo "Master Log Pos: ${MASTER_LOG_POS}" >> /tmp/master_info.txt

 

systemctl stop mysql
cp /tmp/mysqld_slave.cnf  /etc/mysql/mysql.conf.d/mysqld.cnf
systemctl start mysql

mysql -u root -p <<EOF
CHANGE MASTER TO
MASTER_HOST='192.168.1.141',
MASTER_USER='replication',
MASTER_PASSWORD='password',
MASTER_LOG_FILE='$(cat /tmp/master_info.txt | head -n 1 | cut -d ":" -f 2)',
MASTER_LOG_POS=$(cat /tmp/master_info.txt | tail -n 1 | cut -d ":" -f 2);
START SLAVE;
EOF

# Проверка статуса репликации
mysql -u root -p -e "SHOW SLAVE STATUS\G"
