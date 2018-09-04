#!/bin/bash
												  																			
#https://int.bold-ventures.de/confluence/display/SEOW/ELK-Installation+auf+dem+Arbeitsrechner																																  
# ./elasticsearch.sh start        - starts the server and open localhost:9200 for elasticsearch and localhost:5601 for kibana        
# ./elasticsearch.sh restart      - restarts the server																			  
# ./elasticsearch.sh stop         - stops the server																				  
# ./elasticsearch.sh import       - imports the logstash config file ex. matchmaker-import.logstash.conf	
# ./elasticsearch.sh install      - install elasticsearch, kibana and logstash												

CSV_DIR_INPUT="/Users/markusschnittker/Projekte/sandbox-python/resources"
CSV_DIR_OUTPUT="csv"
CONFIG_FILE_NAME="matchmaker-import.logstash.conf"

# MACOS
INSTALL="brew"
RUN="brew"

# LINUX
# INSTALL="sudo apt-get "
# RUN="sudo"

get_elasticsearch_linux() {
	wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
	echo "deb http://packages.elastic.co/elasticsearch/2.x/debian stable main" | sudo tee -a /etc/apt/sources.list.d/elasticsearch-2.x.list
	sudo apt-get update
}

create_config_file() {
cd ~/
touch $CONFIG_FILE_NAME # create config file

cat > $CONFIG_FILE_NAME <<_EOF_
input {
    file {
        path => "${CSV_DIR_OUTPUT}/*.csv"
        start_position => "beginning"
        sincedb_path => "/dev/null"
    }
}
filter {
    csv {
        separator => ","
        columns => ["date","identifier","device","language","filters","query","pageType","pageUrl","responseTime"]
        convert => {
            "date" => "date_time"
            "responseTime" => "integer"
        }
    }

    mutate {
        remove_field => ["host", "path"]
        gsub => [
            "filters", "\[", "",
            "filters", "\]", "",
            "filters", " ", ""
        ]
        split => { "filters" => "," }
    }
}
output {
    elasticsearch {
        hosts => "http://localhost:9200"
        index => "matchmaker-log"
    }
    stdout {}
}
_EOF_
}

start_server() {
	$RUN services start elasticsearch
	$RUN services start kibana
	$RUN services start logstash
	
	# open the browser
	open http://localhost:9200/
	open http://localhost:5601/
}

install_server() {
	# only for linux systems
	# get_elasticsearch_linux
	
	# only for mac os
	brew update
	
	$INSTALL install elasticsearch
	$INSTALL install kibana
	$INSTALL install logstash
}

stop_server() {
	$RUN services stop elasticsearch
	$RUN services stop kibana
	$RUN services stop logstash
}

restart_server() {
	$RUN services restart elasticsearch
}

import_data() {
	cd ~/
	mkdir $CSV_DIR_OUTPUT # create dir ~/csv
	
	for FILE in $CSV_DIR_INPUT/*.csv; do
		FILE_OUTPUT=${FILE//$CSV_DIR_INPUT/''} # remove old file path
	    grep -E "([0-9]{2})T([0-9]{2})" $FILE > $CSV_DIR_OUTPUT/$FILE_OUTPUT # change file structure
	done
	
	sudo logstash -f $CONFIG_FILE_NAME
}

how_to() {
	echo "ElasticSearch Script :"
	echo "./elasticsearch.sh start        - starts the server and open localhost:9200 for elasticsearch and localhost:5601 for kibana"    
	echo "./elasticsearch.sh restart      - restarts the server"																		  
	echo "./elasticsearch.sh stop         - stops the server"																			  
	echo "./elasticsearch.sh import       - imports the logstash config file ex. matchmaker-import.logstash.conf"	
	echo "./elasticsearch.sh install      - install elasticsearch, kibana and logstash"	
}

case $1 in
install)
	install_server
	create_config_file
	import_data
	start_server
  ;;
start)
	start_server
  ;;
stop)
	stop_server
  ;;
restart)
	restart_server
  ;;
import)
	create_config_file
	import_data
	start_server
  ;;
*)
	how_to
  ;;
esac