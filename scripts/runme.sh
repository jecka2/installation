#!/bin/bash 
# Указываем имя файла, который ищем
FILE_NAME="db_files.zip"
MAIN_DIR=$(dirname "$PWD")

# Указываем путь к папке, в которой ищем файл
FOLDER_PATH="/tmp/backup"


# Разворачивание из Гитхаб конфигов,скриптов
cd /tmp
git clone https://github.com/jecka2/installation.git



# Функция для очистки экрана
clear_screen() {
    clear
}

# Меню выбора
show_menu() {
    clear_screen
    echo "Выберите действие:"
    echo "1. Только предварительное конфигурирование серверов"
    echo "2. Только восстановление  конфигурации на уже сконфигурированные сервера "
    echo "3. Восстановление с 0 выполнение пунктов 1 и 2 "
    echo "4. Выход из программы "
    read -p "Ваш выбор: " choice
}

configure () 
{

 echo  "ВВедите имя пользователя для доступа к сервера по ssh:"
 read  user
 echo "ВВедите ip адресс серера фронта:"
 read  front
 #if check_ip "$front"; then
 echo  "Введите ip адресс сервера back+masterbd:"
 read  back_master
 #if check_ip "$back_master"; then
 echo "Введите ip адресс сервера back+replbd:"
 read  back_repl
 #if check_ip "$back_repl"; then
 echo "ВВедите ip адресс серевера логирования и мониторинга:"
 read log_mon
 #if check_ip "$log_mon"; then

 ssh-copy-id $user@$front
 ssh-copy-id $user@$back_master
 ssh-copy-id $user@$back_repl
 ssh-copy-id $user@$log_mon



 # Установвка необходимого ПО подготовка и сетевая настройка
 #Базовая установка ПО и сетевая настройка для сервера фронт 
 scp  ../$MAIN_DIR/scripts/preconfig.sh $user@$front:/tmp/          
 ssh -t $user@$front "sudo bash  /tmp/preconfig.sh front"

 #Базовая установка ПО, подготовка для включеия репликации и сетевая настройка сервера Бэкэнд и мастер базы 
 scp  ../$MAIN_DIR/scripts/preconfig.sh $user@$back_master:/tmp/
 scp  ../$MAIN_DIR/configs/backmaster/mysqld_main.cnf $user@$back_master:/tmp/mysqld_main.cnf
 scp  ../$MAIN_DIR/configs/backmaster/000-default.conf $user@$back_master:/tmp/
 ssh -t $user@$back_master "sudo bash  /tmp/preconfig.sh backmaster"


 #Базовая установка ПО, подготовка для  включения репликации и сетевая настройка для Бэкэнд2 и сервера репликации
 scp  ../$MAIN_DIR/scripts/preconfig.sh $user@$back_repl:/tmp/
 scp  ../$MAIN_DIR/configs/backrepl/mysqld_slave.cnf $user@$back_repl:/tmp/mysqld_slave.cnf
 scp  ../$MAIN_DIR/configs/backrepl/000-default.conf $user@$back_repl:/tmp/
 ssh -t $user@$back_repl "sudo bash  /tmp/preconfig.sh backrepl"

 #Базовая установка ПО для сервера Мониторинга и Логирования и включения пользователя в необходимые группы 
 scp  ../$MAIN_DIR/scripts/preconfig.sh $user@$log_mon:/tmp/
 echo "Положите пакет для ELK и  Grafana  в директорию '../$MAIN_DIR/installatio/packages' и нажмите любую клавшу"
 read -s -n 1          
 scp -r ../$MAIN_DIR/packages/ $user@$log_mon:/tmp/
 ssh -t $user@$log_mon "sudo bash  /tmp/preconfig.sh mon_log"

}


recovery ()
{
# Изменение для подготовленного стэнда после базового конфигурирования 
front=192.168.1.140
back_master=192.168.1.141
back_repl=192.168.1.142
log_mon=192.168.1.143
if [ -n "$user" ]; then
echo "Используется пользователь $user для подключения к серверам"
		else
echo  "ВВедите имя пользователя для доступа к сервера по ssh:"
read  user
 fi




 # Восстановление конфигурации для серверов
 #Запуск восстановления конфигурации на сервере фронт
 scp  ../$MAIN_DIR/scripts/front_config.sh $user@$front:/tmp/
 scp  ../$MAIN_DIR/configs/front/wordpress $user@$front:/tmp/
 ssh -t $user@$front "sudo bash  /tmp/front_config.sh"


 #Запуск восстановления конфигурации для сервера Бэкэнд и Мастер базы
 scp  ../$MAIN_DIR/scripts/backmaster_config.sh $user@$back_master:/tmp/
 scp  ../$MAIN_DIR /configs/backmaster/000-default.conf $user@$back_master:/tmp/000-default.conf
 echo "Положите файл резервной копии бд и сайта в /tmp/backup  архив должен иметь название db_files.zip  и нажмите любую клавишу для продолжения"
 read -s -n 1

 # Проверяем существование файла резервной копии
 if [[ -f "$FOLDER_PATH/$FILE_NAME" ]]; 
        then
    echo "Файл '$FILE_NAME' найден в папке '$FOLDER_PATH' Продолжаем."
    sleep 2
        else
    echo "Файл '$FILE_NAME' не найден в папке '$FOLDER_PATH'. положите файл с праильным названием и запустите скрипт снова"
    read -s -n 1
    exit 1
 fi

 scp /tmp/backup/$FILE_NAME $user@$back_master:/tmp/
 ssh -t $user@$back_master "sudo bash  /tmp/backmaster_config.sh"


 #Запуск восстановления конфигурации для сервера Бэкэнд2 и базы репликации
 scp ../$MAIN_DIR/scripts/backrepl_config.sh $user@$back_repl:/tmp/
 scp ../$MAIN_DIR/configs/backrepl/000-default.conf $user@$back_repl:/tmp/
 scp ../$MAIN_DIR/scripts/backup.sh $user@$back_repl:/tmp/
 scp /tmp/backup/$FILE_NAME $user@$back_repl:/tmp/ 
 ssh -t $user@$back_repl "sudo bash  /tmp/backrepl_config.sh"

 #Запуск восстановления конфигурации для сервера Логирования и Мониторинга
 scp  ../$MAIN_DIR/scripts/log_mon_config.sh $user@$log_mon:/tmp/
 scp -r ../$MAIN_DIR/configs/log_mon/  $user@$log_mon:/tmp/
 ssh -t $user@$log_mon "sudo bash  /tmp/log_mon_config.sh"

}

# Основная логика программы
main() {
    while true; do
        show_menu

        case $choice in
            1)
                echo "Запускаем конфигурирование серверов"
                sleep 2
                configure
                echo "Конфигурирование завершено, возврат к основному меню"
                sleep 5
                ;;
            2)
                echo "Запускаем восстановление на предварительно настроенных серверах"
                sleep 3
                recovery
                echo "Конфигурирование завершено, возврат к основному меню"
                sleep 5
                ;;
            3)
                echo "Запускаем цикл полный цикл восстановления"
                configure
                recovery
                echo "Восстановление завршено прошу проверить восстановление обратившись с помощью браузеран на сайт http:\\192.168.1.140"
                sleep 5
                breake
                ;;

            4)  echo "Завершение программы и очистка временных файлов"
                rm -R /tmp/installation
                break
                ;;

            *)
                echo "Неверный ввод. Попробуйте снова."
                sleep 2
                ;;
        esac
    done
}

# Запуск основной функции
main



