









Пояснительная Записка к сервису




“Веб сервис с балансировкой нагрузки”
























1. Введение

	1.1 Описание проектного решения
	
	Для предоставления веб сервиса с балансировкой нагрузки развернуты следующие сервера:


Номер	Имя сервера	Установленное ПО	IP адрес	Задача
1	front	Nginx	192.168.1.140	Фронт сервер
2	back_master	Mysql, Apache	192.168.1.141	Бэкэнд + Master Database
3	back_repl	Mysql, Apache	192.168.1.142	Бэкэнд+ Серевер репликаций БД
4	log_mon	Prometheus+ Grafana, ELK stack	192.168.1.143	Сервер монитринга и логирования




%3CmxGraphModel%3E%3Croot%3E%3CmxCell%20id%3D%220%22%2F%3E%3CmxCell%20id%3D%221%22%2Рис.1 Ообщая схема работы веб сервиса с балансировкой 0%20%D0%91%D1%8D%D0%BA%D1%8D%D0%BD%D0%B4%20%2B%26amp%3Bnbsp%3B%26lt%3Bdiv%26gt%3B%26amp%3Bnbsp%3B%D0%A1%D0%B5%D1%80%D0%B2%D0%B5%D1%80%20%D1%80%D0%B5%D0%BF





%D0%BB%D0%B8%D0%BA%D0%B0%D1%86%D0%B8%D0%B8%20%D0%91%D0%94%26lt%3B%
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
 4) После этих действий инсталятор ( скрипт ) запросит у вас данные  от 4 серверов которые будут выполнять эти функции, так же сервер запросит ввести учетную запись с помиощью которой он будет подключаться к данным серверам. После выполнения скрипта будет проведена  первичная настройка – Сетевая настройка, обновление текущих пакетов и установка требуемых для поднятия сервисов пакетов. После чего будет производится подключение к предварительно настроенным серверам и прозводиться настройка сервисов согласно предварительно сохраненной конфигурации. При этом скрпт запросит так же предоставить ему архив содержащий набор ранее сохраненых данных ( базы данных  и копию CMS Wordpress )   style%3D%22verticalLabelPosition%3Dbottom%3Bsketch%3D0%3Baspect%3Dfixed%3Bhtml%3D1%3BverticalAlign%3Dtop%3BstrokeColor%3Dnone%3Balign%3Dcenter%3BoutlineConnect%3D0%3Bshape%3Dmxgraph.citrix.database_server%3B%22%20vertex%3D%221%22%20parent%3D%221%22%3E%3CmxGeometry%20x%3D%22550%22%20y%3D%22324%22%20width%3D%2280%22%20height%3D%2290%22%20as%3D%22geometry%22%2F%3E%3C%2FmxCell%3E%3CmxCell%20id%3D%223%22%20value%3D%22%D0%A1%D0%B5%D1%80%D0%B2%D0%B5%D1%80%20%D0%91%D1%8D%D0%BA%D1%8D%D0%BD%D0%B4%2B%26lt%3Bdiv%26gt%3B%D0%A1%D0%B5%D1%80%D0%B2%D0%B5%D1%80%20%D0%BC%D0%B0%D1%81%D1%82%D0%B5%D1%80%20%D0%91%D0%B0%D0%B7%D1%8B%26lt%3B%2Fdiv%26gt%3B%22%20style%3D%22verticalLabelPosition%3Dbottom%3Bsketch%3D0%3Baspect%3Dfixed%3Bhtml%3D1%3BverticalAlign%3Dtop%3BstrokeColor%3Dnone%3Balign%3Dcenter%3BoutlineConnect%3D0%3Bshape%3Dmxgraph.citrix.database_server%3B%22%20vertex%3D%221%22%20parent%3D%221%22%3E%3CmxGeometry%20x%3D%22550%22%20y%3D%22490%22%20width%3D%2280%22%20height%3D%2290%22%20as%3D%22geometry%22%2F%3E%3C%2FmxCell%3E%3CmxCell%20id%3D%224%22%20value%3D%22Frontend%22%20style%3D%22verticalLabelPosition%3Dbottom%3Bsketch%3D0%3Baspect%3Dfixed%3Bhtml%3D1%3BverticalAlign%3Dtop%3BstrokeColor%3Dnone%3Balign%3Dcenter%3BoutlineConnect%3D0%3Bshape%3Dmxgraph.citrix.desktop_web%3B%22%20vertex%3D%221%22%20parent%3D%221%22%3E%3CmxGeometry%20x%3D%22386.75%22%20y%3D%22420%22%20width%3D%2276.5%22%20height%3D%2290%22%20as%3D%22geometry%22%2F%3E%3C%2FmxCell%3E%3CmxCell%20id%3D%225%22%20value%3D%22%D0%A1%D0%B5%D1%80%D0%B2%D0%B5%D1%80%20%D0%9C%D0%BE%D0%BD%D0%B8%D1%82%D0%BE%D1%80%D0%B8%D0%BD%D0%B3%20%D0%B8%26amp%3Bnbsp%3B%26lt%3Bdiv%26gt%3B%D0%9B%D0%BE%D0%B3%D0%B8%D1%80%D0%BE%D0%B2%D0%B0%D0%BD%D0%B8%D1%8F%26lt%3B%2Fdiv%26gt%3B%22%20style%3D%22verticalLabelPosition%3Dbottom%3Bsketch%3D0%3Baspect%3Dfixed%3Bhtml%3D1%3BverticalAlign%3Dtop%3BstrokeColor%3Dnone%3Balign%3Dcenter%3BoutlineConnect%3D0%3Bshape%3Dmxgraph.citrix.command_center%3B%22%20vertex%3D%221%22%20parent%3D%221%22%3E%3CmxGeometry%20x%3D%22720%22%20y%3D%22414%22%20width%3D%2275.5%22%20height%3D%2296%22%20as%3D%22geometry%22%2F%3E%3C%2FmxCell%3E%3CmxCell%20id%3D%226%22%20value%3D%22%D0%9A%D0%BB%D0%B8%D0%B5%D0%BD%D1%82%22%20style%3D%22verticalLabelPosition%3Dbottom%3Bsketch%3D0%3Baspect%3Dfixed%3Bhtml%3D1%3BverticalAlign%3Dtop%3BstrokeColor%3Dnone%3Balign%3Dcenter%3BoutlineConnect%3D0%3Bshape%3Dmxgraph.citrix.laptop_2%3B%22%20vertex%3D%221%22%20parent%3D%221%22%3E%3CmxGeometry%20x%3D%2230%22%20y%3D%22480%22%20width%3D%2262.36%22%20height%3D%2246.5%22%20as%3D%22geometry%22%2F%3E%3C%2FmxCell%3E%3CmxCell%20id%3D%227%22%20value%3D%22Internet%22%20style%3D%22ellipse%3Bshape%3Dcloud%3BwhiteSpace%3Dwrap%3Bhtml%3D1%3B%22%20vertex%3D%221%22%20parent%3D%221%22%3E%3CmxGeometry%20x%3D%22160%22%20y%3D%22446.5%22%20width%3D%22120%22%20height%3D%2280%22%20as%3D%22geometry%22%2F%3E%3C%2FmxCell%3E%3CmxCell%20id%3D%228%22%20value%3D%22%22%20style%3D%22endArrow%3Dclassic%3Bhtml%3D1%3Brounded%3D0%3B%22%20edge%3D%221%22%20source%3D%224%22%20target%3D%222%22%20parent%3D%221%22%3E%3CmxGeometry%20width%3D%2250%22%20height%3D%2250%22%20relative%3D%221%22%20as%3D%22geometry%22%3E%3CmxPoint%20x%3D%22400%22%20y%3D%22430%22%20as%3D%22sourcePoint%22%2F%3E%3CmxPoint%20x%3D%22450%22%20y%3D%22380%22%20as%3D%22targetPoint%22%2F%3E%3C%2FmxGeometry%3E%3C%2FmxCell%3E%3CmxCell%20id%3D%229%22%20value%3D%22%22%20style%3D%22endArrow%3Dclassic%3Bhtml%3D1%3Brounded%3D0%3B%22%20edge%3D%221%22%20source%3D%224%22%20target%3D%223%22%20parent%3D%221%22%3E%3CmxGeometry%20width%3D%2250%22%20height%3D%2250%22%20relative%3D%221%22%20as%3D%22geometry%22%3E%3CmxPoint%20x%3D%22510%22%20y%3D%22580%22%20as%3D%22sourcePoint%22%2F%3E%3CmxPoint%20x%3D%22560%22%20y%3D%22530%22%20as%3D%22targetPoint%22%2F%3E%3C%2FmxGeometry%3E%3C%2FmxCell%3E%3CmxCell%20id%3D%2210%22%20value%3D%22%22%20style%3D%22endArrow%3Dclassic%3Bhtml%3D1%3Brounded%3D0%3B%22%20edge%3D%221%22%20target%3D%224%22%20parent%3D%221%22%3E%3CmxGeometry%20width%3D%2250%22%20height%3D%2250%22%20relative%3D%221%22%20as%3D%22geometry%22%3E%3CmxPoint%20x%3D%2290%22%20y%3D%22510%22%20as%3D%22sourcePoint%22%2F%3E%3CmxPoint%20x%3D%22450%22%20y%3D%22380%22%20as%3D%22targetPoint%22%2F%3E%3CArray%20as%3D%22points%22%3E%3CmxPoint%20x%3D%2290%22%20y%3D%22510%22%2F%3E%3C%2FArray%3E%3C%2FmxGeometry%3E%3C%2FmxCell%3E%3CmxCell%20id%3D%2211%22%20value%3D%22%22%20style%3D%22verticalLabelPosition%3Dbottom%3Bsketch%3D0%3Baspect%3Dfixed%3Bhtml%3D1%3BverticalAlign%3Dtop%3BstrokeColor%3Dnone%3Balign%3Dcenter%3BoutlineConnect%3D0%3Bshape%3Dmxgraph.citrix.firewall%3B%22%20vertex%3D%221%22%20parent%3D%221%22%3E%3CmxGeometry%20x%3D%22310%22%20y%3D%22457%22%20width%3D%2242.74%22%20height%3D%2253%22%20as%3D%22geometry%22%2F%3E%3C%2FmxCell%3E%3CmxCell%20id%3D%2212%22%20value%3D%22%22%20style%3D%22endArrow%3Dclassic%3Bhtml%3D1%3Brounded%3D0%3B%22%20edge%3D%221%22%20source%3D%225%22%20target%3D%223%22%20parent%3D%221%22%3E%3CmxGeometry%20width%3D%2250%22%20height%3D%2250%22%20relative%3D%221%22%20as%3D%22geometry%22%3E%3CmxPoint%20x%3D%22620%22%20y%3D%22750%22%20as%3D%22sourcePoint%22%2F%3E%3CmxPoint%20x%3D%22670%22%20y%3D%22700%22%20as%3D%22targetPoint%22%2F%3E%3C%2FmxGeometry%3E%3C%2FmxCell%3E%3CmxCell%20id%3D%2213%22%20value%3D%22%22%20style%3D%22endArrow%3Dclassic%3Bhtml%3D1%3Brounded%3D0%3B%22%20edge%3D%221%22%20source%3D%225%22%20target%3D%222%22%20parent%3D%221%22%3E%3CmxGeometry%20width%3D%2250%22%20height%3D%2250%22%20relative%3D%221%22%20as%3D%22geometry%22%3E%3CmxPoint%20x%3D%22400%22%20y%3D%22430%22%20as%3D%22sourcePoint%22%2F%3E%3CmxPoint%20x%3D%22450%22%20y%3D%22380%22%20as%3D%22targetPoint%22%2F%3E%3C%2FmxGeometry%3E%3C%2FmxCell%3E%3CmxCell%20id%3D%2214%22%20value%3D%22%22%20style%3D%22endArrow%3Dclassic%3Bhtml%3D1%3Brounded%3D0%3B%22%20edge%3D%221%22%20source%3D%225%22%20target%3D%224%22%20parent%3D%221%22%3E%3CmxGeometry%20width%3D%2250%22%20height%3D%2250%22%20relative%3D%221%22%20as%3D%22geometry%22%3E%3CmxPoint%20x%3D%22400%22%20y%3D%22430%22%20as%3D%22sourcePoint%22%2F%3E%3CmxPoint%20x%3D%22480%22%20y%3D%22460%22%20as%3D%22targetPoint%22%2F%3E%3C%2FmxGeometry%3E%3C%2FmxCell%3E%3C%2Froot%3E%3C%2FmxGraphModel%3E


