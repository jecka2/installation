#!/bin/bash

# Настройки подключения к базе данных
MYSQL_USER="root"
BACKUP_DIR="/tmp/backup"
SITE_DIR="wordpress"
TIMESTAMP=$(date +"%Y-%m-%d")

 

# Получаем список всех баз данных
databases=$(mysql -u "$MYSQL_USER" -Bse "show databases")

# Создаем директорию для текущего бэкапа
mkdir -p "$BACKUP_DIR"
mkdir -p "$BACKUP_DIR/BASE"

# Проходим по всем базам данных
for db in $databases; do
    if [[ "$db" != "information_schema" && "$db" != "performance_schema" && "$db" != "sys" ]]; then
        echo "Создаём резервную копию базы данных: $db"

        # Получаем список всех таблиц в базе данных
        tables=$(mysql -u "$MYSQL_USER" -p"$MYSQL_PASS" -Bse "use $db; show tables;")

        # Создаем папку для данной базы данных
        mkdir -p "$BACKUP_DIR/BASE/$db"

        # Проходим по всем таблицам
        for table in $tables; do
            echo "Создаём дамп таблицы: $table"

            # Получаем текущие позиции бинарного лога
            binlog_info=$(mysql -u "$MYSQL_USER" -Bse "SHOW MASTER STATUS\G" | grep -E '(File|Position)')
            master_log_file=$(echo "$binlog_info" | awk '/File/{print $NF}')
            exec_master_log_pos=$(echo "$binlog_info" | awk '/Position/{print $NF}')

            # Создаем дамп таблицы
            mysqldump -u "$MYSQL_USER"  --single-transaction --master-data=2 --lock-tables=false --set-gtid-purged=OFF   --flush-logs --hex-blob -- "$db" "$table" > "$BACKUP_DIR/BASE/$db/${table}.sql"

            # Записываем информацию о позиции бинарного лога в файл binlog_info.txt
            echo "Master_Log_File: $master_log_file" > "$BACKUP_DIR/BASE/$db/binlog_info.txt"
            echo "Exec_Master_Log_Pos: $exec_master_log_pos" >> "$BACKUP_DIR/BASE/$db/binlog_info.txt"
        done
    fi
done

echo "Резервное копирование завершено в $BACKUP_DIR"


rsync -avz /var/www/html/${SITE_DIR}/ ${BACKUP_DIR}/${SITE_DIR}           


mkdir ~/backup
cd /tmp    
zip -r ~/backup/db_files.zip_$TIMESTAMP $BACKUP_DIR

echo "Полный архив расположен в ~/backup"
