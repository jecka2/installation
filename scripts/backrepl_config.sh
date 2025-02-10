#!/bin/bash


#cd /tmp
#wget https://wordpress.org/latest.tar.gz
#tar xzvf latest.tar.gz
#mv wordpress /var/www/html/
#cd /var/www/html/wordpress
#cp wp-config-sample.php wp-config.php

rm -R /var/www/html/wordpress
cp /tmp/000-default.conf /etc/apache2/sites-available/

#chown -R www-data:www-data  /var/www/html/wordpress


#Разархивирования архива с данными и применение правна файлы

unzip -d /  /tmp/db_files.zip
sudo cp -R  /tmp/backup/wordpress /var/www/html/
sudo chown -R  www-data:www-data /var/www/html/wordpress
cp /tmp/backup.sh ~/ 

#Создания задания для резервного копирования баз данных и файлов
# Путь к вашему скрипту
SCRIPT_PATH="~/backup.sh"

# Строка для добавления в crontab
CRON_ENTRY="0 23 * * * $SCRIPT_PATH"

# Проверяем, существует ли уже такая строка в crontab
if ! crontab -l | grep "$CRON_ENTRY"; then
    # Добавляем новую строку в crontab
    (crontab -l ; echo "$CRON_ENTRY") | crontab -
fi


# Получаем имя текущего пользователя
USERNAME=$(whoami)

# Удаляем правило из файла sudoers
sudo sed -i "/%$USERNAME ALL=(ALL) NOPASSWD: ALL/d" /etc/sudoers

# Проверяем успешность операции
if [ $? -eq 0 ]; then
    echo "Запрос пароля для sudo включен для пользователя $USERNAME."
    sleep 10
else
    echo "Ошибка при попытке восстановить настройки sudo для пользователя $USERNAME."
    sleep 10
fi
