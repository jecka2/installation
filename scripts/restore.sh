#!/bin/bash

# Настройки подключения к базе данных
MYSQL_USER="root"
MYSQL_PASS="password"
BACKUP_DIR="/tmp/backup/BASE"

# Указать папку с архивом
echo "Прошу указать путь до файла с архивом"
read DIR

#Разархивирования архива с данными и применение правна файлы
unzip -d / ~/backup/db_files.zip
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
