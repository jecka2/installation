﻿









Пояснительная Записка к сервису




“Веб сервис с балансировкой нагрузки”
























1. Введение

	1.1 Описание проектного решения
	
	Для предоставления веб сервиса с балансировкой нагрузки развернуты следующие сервера:

__________________________________________________________________________________________________
|Номер	|Имя сервера	|Установленное ПО	|IP адрес	|Задача				  |
|1	|front	        |Nginx			|192.168.1.140	|Фронт сервер			  |
|_______|_______________|_______________________|_______________|_________________________________|
|2	|back_master	|Mysql, Apache		|192.168.1.141	|Бэкэнд + Master Database	  |
|_______|_______________|_______________________|_______________|_________________________________|
|3	|back_repl	|Mysql, Apache		|192.168.1.142	|Бэкэнд+ Серевер репликаций БД    |
|_______|_______________|_______________________|_______________|_________________________________|
|4	|log_mon	|Prometheus+ Grafana,   |192.168.1.143  |Сервер монитринга и логирования  |
|       |               |  ELK stack	                       
|_______|_______________|_______________________|_______________|__________________________________|



/io.png
1 Ообщая схема работы веб сервиса с балансировкой 

	1.2	Описание работы Сервиса :
 Необхордимо произвести развертывние 4 серверов с ОС Ubuntu и произвести следующие настройки:
1) Сервер будет являться фронтэнд сервером с веб сервисом Nginx при приеме Http запросов на порт 80 будет производить перенаправление запросов на один из серверов Бэкэнд.
2) На сервере Бэкэнд + Сервер мастер Базы производится установка сервера Mysql который будет использоваться в качестве сервера баз данных для расположенной на серверах Бэкэнд CMS Wordpress. Так же на данном сервере производится настройка доступа для проведения реплекаций БД. В качкестве веб сервиса будет выступать по apache2
3) Сервер Бэкэнд+ Серевер репликаций производится настройка сервиса Mysql для проведения реплекаций БД с  мастер сервера. В качестве веб сервиса будет выступать по apache2 c развернутой на нем CMS Wordpress. На данном сервере будет  производится резеревное копирование всех БД и самой CMS WordPress
4) Сервер Мониторинга и Логирования включает в себя установку ПО prometheus+grafana в качестве системы мониторинга и сбоа метрик, а так же ELK стэк для сбора и обработки логов.



2. Резервное копирование 
В качестве резервного сохранения данных выбрано следующее решение:
1) Конфигурации основного ПО, а так же скрипты для восстановления и резерного копирования  расположены на github
2) Резервные копии БД и сайта производятся ежденевно в 23:00 и переносятся на отдельный сервер 



3. Новая инсталяция сервиса


В случае необходмиости равзвернуть второй экземпляр данного решения в другой сети необходимо произвести следующие действия:

1) Развернуть 4 сервера и установить ос Ubuntu

2)На рабочей станции с установленной ос Linux в терминале выполнить  следующие команды:
 git clone https://github.com/jecka2/installation.git
 cd /installation/scripts/
 bash runme.sh

3) В запущеном скрипте выбрать: 1 Только предвартильное конфигурирование
После этих действий инсталятор ( скрипт ) запросит у вас данные  от 4 серверов которые будут выполнять эти функции, так же сервер запросит ввести учетную запись с помиощью которой он будет подключаться к данным серверам. После выполнения скрипта будет проведена  первичная настройка – Сетевая настройка, обновление текущих пакетов и установка требуемых для поднятия сервисов пакетов.




4. Полное восстановление 


В случае если понадобиться полное восстановление системы с 0 необходимы следующие действия:

1) Развернуть 4 сервера и установить ос Ubuntu

2)На рабочей станции с установленной ос Linux в терминале выполнить  следующие команды:
 git clone https://github.com/jecka2/installation.git
 cd /installation/scripts/
 bash runme.sh

3) В запущеном скрипте выбрать: 3 Восстановление с 0 выполнение пунктов 1 и 2 
 4) После этих действий инсталятор ( скрипт ) запросит у вас данные  от 4 серверов которые будут выполнять эти функции, так же сервер запросит ввести учетную запись с помиощью которой он будет подключаться к данным серверам. После выполнения скрипта будет проведена  первичная настройка – Сетевая настройка, обновление текущих пакетов и установка требуемых для поднятия сервисов пакетов. После чего будет производится подключение к предварительно настроенным серверам и прозводиться настройка сервисов согласно предварительно сохраненной конфигурации. При этом скрпт запросит так же предоставить ему архив содержащий набор ранее сохраненых данных ( базы данных  и копию CMS Wordpress )   
