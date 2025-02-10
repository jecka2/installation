#!/bin/bash


rm /etc/nginx/sites-enabled/default
cp /tmp/wordpress /etc/nginx/sites-available
ln -s /etc/nginx/sites-available/wordpress  /etc/nginx/sites-enabled/wordpress


systemctl stop nginx
systemctl start nginx



# Получаем имя текущего пользователя
USERNAME=$(whoami)

# Удаляем правило из файла sudoers
sudo sed -i "/%$USERNAME ALL=(ALL) NOPASSWD: ALL/d" /etc/sudoers

# Проверяем успешность операции
if [ $? -eq 0 ]; then
    echo "Запрос пароля для sudo включен для пользователя $USERNAME."
else
    echo "Ошибка при попытке восстановить настройки sudo для пользователя $USERNAME."
fi

