#!/bin/bash


touch /var/log/restore_error.log
exec 2>/var/log/restore_error.log




if [[ "$1" == "front" ]];
        then




		rm /etc/nginx/sites-enabled/default
		cp /tmp/wordpress /etc/nginx/sites-available
		ln -s /etc/nginx/sites-available/wordpress  /etc/nginx/sites-enabled/wordpress

		STATUS=$(systemctl is-active filebeat.service)

        	if [[ "$STATUS" == "active" ]]; then

        	systemctl stop filebeat.service
                	else
        		echo "Fileberat не запущена, продолжаем"

        	fi

		cp /tmp/filebeat.yml /etc/filebeat/filebeat.yml

		systemctl start filebeat.service

		systemctl stop nginx
		systemctl start nginx



elif [[ "$1" == "backmaster" ]];
        then



		# Настройки подключения к базе данных
		MYSQL_USER="root"
		BACKUP_DIR="/tmp/backup/BASE"



		systemctl stop mysql
		#cp /tmp/mysqld_main.cnf  /etc/mysql/mysql.conf.d/mysqld.cnf
		systemctl start mysql

		
		sudo rm -R /var/www/html/wordpress
		cp /tmp/000-default.conf /etc/apache2/sites-available

		#systemctl restart apache2

		#chown -R www-data:www-data  /var/www/html/wordpress

		
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



#Восстановление Бэка и реплиткации
elif [[ "$1" == "backrepl" ]];
        then


	SCRIPT_PATH="~/backup.sh"


	rm -R /var/www/html/wordpress
	cp /tmp/000-default.conf /etc/apache2/sites-available/


	#Разархивирования архива с данными и применение правна файлы

	unzip -d /  /tmp/db_files.zip
	sudo cp -R  /tmp/backup/wordpress /var/www/html/
	sudo chown -R  www-data:www-data /var/www/html/wordpress
	cp /tmp/backup.sh ~/

	#Создания задания для резервного копирования баз данных и файлов
	# Путь к вашему скрипту

	# Строка для добавления в crontab
	CRON_ENTRY="0 23 * * * $SCRIPT_PATH"

	# Проверяем, существует ли уже такая строка в crontab
	if ! crontab -l | grep "$CRON_ENTRY"; then
    		# Добавляем новую строку в crontab
    		(crontab -l ; echo "$CRON_ENTRY") | crontab -
	fi


else



	DIR=/tmp/log_mon
	
	STATUS=$(systemctl is-active grafana-server.service)

	if [[ "$STATUS" == "active" ]]; then
  
  	systemctl stop grafana-server.service
		else
	echo "Графана не запущена, продолжаем"
  	
	fi
			
	cp $DIR/grafana.db /var/lib/grafana.db
	chown grafana:grafana /var/lib/grafana.db
	
	systemctl start grafana-server.service
	systemctl stop promtheus
	
	cp $DIR/prometheus.yml /etc/prometheus/prometheus.yml
	systemctl start prometheus


	cp $DIR/elasticsearch.yml /etc/elasticsearch/elasticsearch.yml
	systemctl enable --now elasticsearch.service

	cp $DIR/kibana.yml /etc/kibana/kibana.yml
	systemctl enable --now kibana.service

	cp $DIR/logstash.yml /etc/logstash/
	cp $DIR/logstash-nginx-es.conf /etc/logstash/conf.d/
	systemctl enable --now logstash.service


	cp $DIR/filebeat.yml  /etc/filebeat/
	filebeat modules enable nginx
	
	cp $DIR/nginx.yml /etc/filebeat/modules.d/
	systemctl start filebeat
	grafana-cli admin reset-admin-password 123qweASD!


	systemctl restart elasticsearch
	systemctl restart kibana
	systemctl restart filebeat
	systemctl restart logstash
	systemctl restart prometheus

fi 



# Получаем имя текущего пользователя
USERNAME=($2)

# Удаляем правило из файла sudoers
sudo sed -i "/%$USERNAME ALL=(ALL) NOPASSWD: ALL/d" /etc/sudoers

# Проверяем успешность операции
if [ $? -eq 0 ]; then
    echo "Запрос пароля для sudo включен для пользователя $USERNAME."
    sleep 3
else
    echo "Ошибка при попытке восстановить настройки sudo для пользователя $USERNAME."
    sleep 3
fi
