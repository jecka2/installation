#!/bin/bash


USERNAME=($2)
echo $2

# Редактируем файл sudoers
echo "%$USERNAME ALL=(ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers.d/$USERNAME

# Проверяем успешность операции
if [ $? -eq 0 ]; then
    echo "Запрос пароля для sudo отключен для пользователя $USERNAME."
    sleep 1
else
    echo "Ошибка при попытке изменить настройки sudo для пользователя $USERNAME."
    sleep 1 
fi

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

echo $1
touch /var/log/configure_error.log
touch /var/log/configure_log.log
exec 2>/var/log/configure_error.log



if [[ "$1" == "backmaster" ]]; 
	then

# Переменные для настройки сети
IP_ADDRESS="192.168.1.141"   # Статический IP-адрес
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
apt-get install mysql-server git apache2 prometheus-node-exporter rsyslog rsyslog-gnutls php libapache2-mod-php php-mysql zip -y


# Создание пользователя для репликации
SQL_COMMANDS="
CREATE USER 'replication'@'192.168.1.142' IDENTIFIED BY 'password';
GRANT REPLICATION SLAVE ON *.* TO 'replication'@'192.168.1.142';
FLUSH PRIVILEGES;
"
mysql -u root -e "${SQL_COMMANDS}"



systemctl stop mysql
cp /tmp/mysqld_main.cnf  /etc/mysql/mysql.conf.d/mysqld.cnf
systemctl start mysql


cd /tmp
wget https://wordpress.org/latest.tar.gz
tar xzvf latest.tar.gz
sudo mv wordpress /var/www/html/

chown -R www-data:www-data /var/www/html/wordpress

cp /tmp/000-default.conf /etc/apache2/sites-available/

echo "module(load="imuxsock") # local message reception" >> /etc/rsyslog.conf
echo "module(load="imklog")   # kernel message reception" >> /etc/rsyslog.conf

# Send logs to Logstash over TCP with TLS encryption
echo "$ActionSendStreamDriverPermittedPeer 192.168.1.144 # замените на ваше доменное имя или IP-адрес сервера Logstash" >> /etc/rsyslog.conf

echo "*.* 192.168.1.144:5400 # замените на адрес и порт вашего Logstash" >>/etc/rsyslog.conf

reboot now
  


elif [[ "$1" == "backrepl" ]]; 
	then

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
apt-get install mysql-server git apache2 prometheus-node-exporter  rsyslog rsyslog-gnutls php libapache2-mod-php php-mysql zip  -y


systemctl stop mysql
cp /tmp/mysqld_slave.cnf  /etc/mysql/mysql.conf.d/mysqld.cnf
systemctl start mysql


SQL_COMMANDS="
STOP REPLICA;
CHANGE REPLICATION SOURCE TO SOURCE_HOST='192.168.1.141', SOURCE_USER='replication', SOURCE_PASSWORD='password', SOURCE_AUTO_POSITION = 1, GET_SOURCE_PUBLIC_KEY = 1;
START REPLICA;
"
mysql -u root -e "${SQL_COMMANDS}"


# Проверка статуса репликации
mysql -uroot -e "SHOW SLAVE STATUS\G"

cd /tmp
wget https://wordpress.org/latest.tar.gz
tar xzvf latest.tar.gz
sudo mv wordpress /var/www/html/

chown -R www-data:www-data /var/www/html/wordpress

cp /tmp/000-default.conf /etc/apache2/sites-available/

reboot now

elif [[ "$1" == "mon_log" ]]; 
	then
# Переменные для настройки сети
IP_ADDRESS="192.168.1.143"   # Статический IP-адрес
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


#Установка софта для mon_log
apt install musl  prometheus   -y
cd /tmp/packages
dpkg -i *.deb

USERNAME=$(whoami)

usermod -a -G elasticsearch $USERNAME
usermod -a -G kibana $USERNAME
usermod -a -G grafana $USERNAME


reboot now





	else 
# Переменные для настройки сети
IP_ADDRESS="192.168.1.140"   # Статический IP-адрес
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


apt install nginx prometheus-node-exporter rsyslog rsyslog-gnutls -y

rm /etc/nginx/sites-avalible/default
cp /tmp/wordpress /etc/nginx/sites-avalible/
ln -s /etc/nginx/sites-available/wordpress  /etc/nginx/sites-enabled/wordpress

dpkg -i /tmp/filebeat-*.deb

sudo reboot now
 fi  
 

