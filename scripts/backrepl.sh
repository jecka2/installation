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
apt-get install mysql-server git apache2  php libapache2-mod-php php-mysql  -y


systemctl stop mysql
cp /tmp/mysqld_slave.cnf  /etc/mysql/mysql.conf.d/mysqld.cnf
systemctl start mysql

mysql -uroot  <<EOF
STOP REPLICA;
CHANGE REPLICATION SOURCE TO SOURCE_HOST='192.168.1.141', SOURCE_USER='replication', SOURCE_PASSWORD='password', SOURCE_AUTO_POSITION = 1, GET_SOURCE_PUBLIC_KEY = 1;
START REPLICA;
EOF

# Проверка статуса репликации
mysql -uroot -e "SHOW SLAVE STATUS\G"


cd /tmp
wget https://wordpress.org/latest.tar.gz
tar xzvf latest.tar.gz
mv wordpress /var/www/html/
cd /var/www/html/wordpress
cp wp-config-sample.php wp-config.php




