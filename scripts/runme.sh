#!/bin/bash 
# Указываем имя файла, который ищем
FILE_NAME="db_files.zip"
MAIN_DIR=$("$PWD")

# Указываем путь к папке, в которой ищем файл
FOLDER_PATH="/tmp/backup"

# Функция для очистки экрана
clear_screen() {
    clear
}

# Меню выбора
show_menu() {
    clear_screen
    echo "Выберите действие:"
    echo "1. Только предварительное конфигурирование серверов"
    echo "2. Только восстановление  конфигурации на уже сконфигурированные сервера"
    echo "3. Восстановление с 0 выполнение пунктов 1 и 2"
    echo "4. Выход из программы"
    read -p "Ваш выбор: " choice
}

# Меню выбора
sub_menu() {
    clear_screen
    echo "Выберите действие:"
    echo "1. Только для фронта"
    echo "2. Только для Бэк Мастер и Слйэв"
    echo "3. Только для мониторинга и логирования"
    echo "4. Для всех серверов"
    echo "5. На уровень выше"
    echo "6. Выход из программы"
    read -p "Ваш выбор: " choice
}


 # Установвка необходимого ПО подготовка и сетевая настройка
configure_front ()
{
 echo "ВВедите ip адресс серера фронта:"
 read  front
 ssh-copy-id $user@$front

 #Базовая установка ПО и сетевая настройка для сервера фронт 
 scp  ../$MAIN_DIR/scripts/preconfig.sh $user@$front:/tmp/
 echo "Положите пакет filebeat в директорию $MAIN_DIR/packages и нажмите любую клавшу"
 read -s -n 1
 scp -r ../$MAIN_DIR/packages/filebeat-* $user@$front:/tmp/
 ssh -t $user@$front "sudo bash  /tmp/preconfig.sh front $user"
}

configure_backs ()
{
 echo  "Введите ip адресс сервера back+masterbd:"
 read  back_master
 echo "Введите ip адресс сервера back+replbd:"
 read  back_repl
 ssh-copy-id $user@$back_master
 ssh-copy-id $user@$back_repl



  #Базовая установка ПО, подготовка для включеия репликации и сетевая настройка сервера Бэкэнд и мастер базы 
  scp  ../$MAIN_DIR/scripts/preconfig.sh $user@$back_master:/tmp/
  scp  ../$MAIN_DIR/configs/backmaster/mysqld_main.cnf $user@$back_master:/tmp/mysqld_main.cnf
  scp  ../$MAIN_DIR/configs/backmaster/000-default.conf $user@$back_master:/tmp/
  ssh -t $user@$back_master "sudo bash  /tmp/preconfig.sh backmaster $user"



  #Базовая установка ПО, подготовка для  включения репликации и сетевая настройка для Бэкэнд2 и сервера репликации
  scp  ../$MAIN_DIR/scripts/preconfig.sh $user@$back_repl:/tmp/
  scp  ../$MAIN_DIR/configs/backrepl/mysqld_slave.cnf $user@$back_repl:/tmp/mysqld_slave.cnf
  scp  ../$MAIN_DIR/configs/backrepl/000-default.conf $user@$back_repl:/tmp/
  ssh -t $user@$back_repl "sudo bash  /tmp/preconfig.sh backrepl $user"
}

configure_mon ()
{
 echo "ВВедите ip адресс серевера логирования и мониторинга:"
 read log_mon
 ssh-copy-id $user@$log_mon
 #Базовая установка ПО для сервера Мониторинга и Логирования и включения пользователя в необходимые группы 
 scp  ../$MAIN_DIR/scripts/preconfig.sh $user@$log_mon:/tmp/
 echo "Положите пакет для ELK и  Grafana  в директорию $MAIN_DIR/packages и нажмите любую клавшу"
 read -s -n 1          
 scp -r ../$MAIN_DIR/packages/ $user@$log_mon:/tmp/
 ssh -t $user@$log_mon "sudo bash  /tmp/preconfig.sh mon_log $user"

}

# Выбор пользователя 
user ()
{
 if [ -n "$user" ]; then
		echo "Используется пользователь $user для подключения к серверам"
		else
		echo  "ВВедите имя пользователя для доступа к сервера по ssh:"
		read  user
 fi
}


 # Восстановление конфигурации для серверов
recovery_front ()
{
 front=192.168.1.140
 #Запуск восстановления конфигурации на сервере фронт
 scp  ../$MAIN_DIR/scripts/recovery.sh $user@$front:/tmp/
 scp  ../$MAIN_DIR/configs/front/wordpress $user@$front:/tmp/
 scp  ../$MAIN_DIR/configs/front/filebeat.yml $user@$front:/tmp/
 ssh -t $user@$front "sudo bash  /tmp/recovery.sh front $user"
}

recovery_backs ()
{
 back_master=192.168.1.141
 back_repl=192.168.1.142
 #Запуск восстановления конфигурации для сервера Бэкэнд и Мастер базы
 scp  ../$MAIN_DIR/scripts/recovery.sh $user@$back_master:/tmp/
 scp  ../$MAIN_DIR/configs/backmaster/000-default.conf $user@$back_master:/tmp/000-default.conf
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
 ssh -t $user@$back_master "sudo bash  /tmp/recovery.sh backmaster $user"


 #Запуск восстановления конфигурации для сервера Бэкэнд2 и базы репликации
 scp ../$MAIN_DIR/scripts/recovery.sh $user@$back_repl:/tmp/
 scp ../$MAIN_DIR/configs/backrepl/000-default.conf $user@$back_repl:/tmp/
 scp ../$MAIN_DIR/scripts/backup.sh $user@$back_repl:/tmp/
 scp /tmp/backup/$FILE_NAME $user@$back_repl:/tmp/ 
 ssh -t $user@$back_repl "sudo bash  /tmp/recovery.sh backrepl $user"
}

#Запуск восстановления конфигурации для сервера Логирования и Мониторинга
recovery_mon()
 {
 log_mon=192.168.1.143
 scp  ../$MAIN_DIR/scripts/recovery.sh $user@$log_mon:/tmp/
 scp -r ../$MAIN_DIR/configs/log_mon/  $user@$log_mon:/tmp/
 ssh -t $user@$log_mon "sudo bash  /tmp/recovery.sh log_mon $user"

}

# Основная логика программы
main() {
    while true; do
	touch /var/log/run_error.log
	exec 2>/var/log/run_error.log
        show_menu

        case $choice in
            1)
                sub_menu
                case $choice in

                        1)
                                echo "Запускаем конфигурированмие сервера фронта"
				user
				configure_front
				echo "Конфигурирование сервера фронт завершено"
				sleep 5
                                ;;
 
                        2)
                                echo "Выбран режим восстанаовлния тольео бэкэндов"
				user
				configure_backs
				echo "Конфигурирование серверов бэк завершено"
                                sleep5
				;;
                        3)
                                echo "Выбран режим восстанлвения  сервера логирования"
				user
				configure_mon
				echo "Конфигурирование сервера логирования заврешено"
                                sleep 5
				;;
                        4)
                                echo "Выбран режим восстановления всех серверов"
				user
                                configure_front
				configure_backs
				configure_mon
                                echo "Конфигурирование серверов завершено"
				sleep 5
                               ;;

                        5)  
                                echo "На уровень вверх"
                                #show_menu
				breake
                                ;;
		   	6)	
				echo "Выход"
				sleep 5
				exit 0
				;;

                        esac
	
                
                #echo "Конфигурирование завершено, возврат к основному меню"
                
                ;;
           2)
                #echo "Запускаем восстановление на предварительно настроенных серверах"
                #sleep 3
  			
		sub_menu
		case $choice in

                        1)
                                echo "Выбран режим восстановление конфигурации сервера фронта"
                                user
				recovery_front
                                echo "Восстановление конфигурации сервера фронт завершено"
                                sleep 5
                                ;;

                        2)
                                echo "Выбран режим восстановления конфигурации только бэкэндов"
                                user
				recovery_backs
                                echo "Восстановление конфигурации серверов бэк завершено"
                                sleep5
                                ;;
                        3)
                                echo "Выбран режим восстанлвения конфигурации сервера логирования"
                                user
				recovery_mon
                                echo "Восстановление конфигурации сервера логирования заврешено"
                                sleep 5
                                ;;
                        4)
                                echo "Выбран режим восстановления всех серверов"
                                user
				recovery_front
                                recovery_backs
                                recovery_mon
                                echo "Восстановление конфигурации всех серверов завершено"
                                sleep 5
                                ;;

                        5)
                                echo "На уровень вверх"
                               # show_menu
				breake
                                ;;
                        6)
                                echo "Выход"
                                sleep 1
                                exit 0
                                ;;
				
			*)	
		                echo "Неверный ввод. Попробуйте снова."
                		sleep 2
               			 ;;

				
                        esac

                
                #echo "Конфигурирование завершено, возврат к основному меню"
                #sleep 5
                ;;
            3)
                echo "Запускаем цикл полный цикл восстановления"
			sub_menu 
			case $choice in              

				1) 
					echo "Выбран режим восстановления фронта"
					user
					configure_front
					sleep 10
					recovery_front 
					;;
 
				2)
					echo "Выбран режим восстановления серверов бэкэнд"
					user
					configure_back
					recovery_backs
  					;;
				3)
					echo "Выбран режим восстановления сервера логирования"
					user
					configure_mon
					sleep 10
					recovery_mon
					;; 
				4)
					echo "Выбран режим восстановления всех серверов" 
					user
					configure_front
					configure_backs
					configure_mon
					recovery_front
					recovery_backs
					recovery_mon
					echo "Восстановление всех серверов завршено"
					echo "Восстановление завршено прошу проверить восстановление обратившись с помощью браузеран на сайт http:\\192.168.1.140"
			                echo "Сервер монитроинг и логирования находится по адресу 192.168.1.143"

 					;;	

				5)
					echo "На уровень вверх"
					brake
					;;
                        	6)
	                                echo "Выход"
        	                        sleep 5
                	                exit 0
                        	        ;;
				*)
                			echo "Неверный ввод. Попробуйте снова."
					sleep 2
                			;;

		
			esac		
 
                 ;;

            4)  echo "Завершение программы и очистка временных файлов"
                #rm -R $MAIN_DIR
                exit 0
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




