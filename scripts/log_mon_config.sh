#/!bin/bash
DIR=/tmp/log_mon

systemctl stop grafana-server.service
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
 
metricbeat setup --dashboards







