#!/bin/bash

# Настройки подключения к базе данных
MYSQL_USER="root"
MYSQL_PASS="password"
BACKUP_DIR="/tmp/backup/BASE"



# Создание пользователя для репликации
SQL_COMMANDS="
CREATE USER 'jecka'@'%' IDENTIFIED BY '123qweASD!';
GRANT ALL PRIVILEGES ON *.* TO 'jecka'@'%';
CREATE DATABASE wp_database;
CREATE USER 'wp_user'@'%' IDENTIFIED BY '123qweASD!';
GRANT ALL PRIVILEGES ON wp_database.* TO 'wp_user'@'%';
FLUSH PRIVILEGES;
"
#mysql -u root -e "${SQL_COMMANDS}"

systemctl stop mysql
#cp /tmp/mysqld_main.cnf  /etc/mysql/mysql.conf.d/mysqld.cnf
systemctl start mysql



#cd /tmp
#wget https://wordpress.org/latest.tar.gz
#tar xzvf latest.tar.gz
#sudo mv wordpress /var/www/html/

sudo rm -R /var/www/html/wordpress
cp /tmp/000-default.conf /etc/apache2/sites-available

#systemctl restart apache2

#chown -R www-data:www-data  /var/www/html/wordpress




# Указать папку с архивом
#echo "Прошу указать путь до файла с архивом"
#read DIR

#Разархивирования архива с данными и применение правна файлы

unzip -d /  /tmp/db_files.zip
sudo cp -R  /tmp/backup/wordpress /var/www/html/
sudo chown -R  www-data:www-data /var/www/html/wordpress


# Проходим по всем папкам в директории backups
for db_dir in "$BACKUP_DIR"/*; do
    if [ -d "$db_dir" ]; then
        # Извлекаем название базы данных из имени папки
        db_name=$(basename "$db_dir")

        # Создаем базу данных, если ее еще нет
        mysql -u "$MYSQL_USER"  -e "CREATE DATABASE IF NOT EXISTS $db_name;"

        # Проходим по всем файлам дампов в этой папке
        for sql_file in "$db_dir"/*.sql; do
            echo "Импортируем файл $sql_file в базу данных $db_name..."
            mysql -u "$MYSQL_USER"  "$db_name" < "$sql_file"
        done

        # Чтение информации о позиции бинарного лога из файла binlog_info.txt
        binlog_info_file="$db_dir/binlog_info.txt"
        if [ -f "$binlog_info_file" ]; then
            master_log_file=$(grep "Master_Log_File:" "$binlog_info_file" | cut -d ':' -f2)
            exec_master_log_pos=$(grep "Exec_Master_Log_Pos:" "$binlog_info_file" | cut -d ':' -f2)

            # Применение позиции бинарного лога для продолжения репликации
            mysql -u "$MYSQL_USER"  -e "STOP SLAVE; CHANGE MASTER TO MASTER_LOG_FILE='$master_log_file', MASTER_LOG_POS=$exec_master_log_pos; START SLAVE;"
        else
            echo "Файл binlog_info.txt отсутствует в папке $db_dir. Позиция бинарного лога не применяется."
        fi
    fi
done

echo "Все базы данных восстановлены!"
 
systemctl restart mysql 




systemctl restart apache2

#!/bin/bash

# Получаем имя текущего пользователя
USERNAME=$(whoami)

# Удаляем правило из файла sudoers
sudo sed -i "/%$USERNAME ALL=(ALL) NOPASSWD: ALL/d" /etc/sudoers

# Проверяем успешность операции
if [ $? -eq 0 ]; then
    echo "Запрос пароля для sudo включен для пользователя $USERNAME."
    sleep 5
else
    echo "Ошибка при попытке восстановить настройки sudo для пользователя $USERNAME."
    sleep 5 
fi


