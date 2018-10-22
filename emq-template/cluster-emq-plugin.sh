#!/usr/bin/sh

#--------------------------------------------------------------------------------------------
# Expecting the following arguments in order -
# <host> = emq集群中任意一个节点的hostname或ip
# <port> = emq集群管理监控api的端口号
# <name_in_zabbix> = web前端页面添加主机时填入的主机名
#--------------------------------------------------------------------------------------------

COMMAND_LINE="$0 $*"
export SCRIPT_NAME="$0"

usage() {
   echo "Usage: $SCRIPT_NAME <host> <port>"
}

if [ $# -ne 3 ]
then
    usage ;
    exit ;
fi


#--------------------------------------------------------------------------------------------
# 第一个参数为emq节点ip或域名
# 第二个参数为管理监控api的端口号
# 第三个参数为web前端页面添加主机时填入的主机名
#--------------------------------------------------------------------------------------------
export EMQ_NODE_IP=$1
export EMQ_NODE_PORT=$2
export NAME_IN_ZABBIX=$3

#--------------------------------------------------------------------------------------------
# Set the data output file and the log fle from zabbix_sender
#--------------------------------------------------------------------------------------------
export DATA_FILE="/tmp/${EMQ_NODE_IP}_${EMQ_NODE_PORT}.txt"
export BAK_DATA_FILE="/tmp/${EMQ_NODE_IP}_${EMQ_NODE_PORT}_bak.txt"
export LOG_FILE="/tmp/${EMQ_NODE_IP}.log"


#--------------------------------------------------------------------------------------------
# Use python to get the node data and use screen-scraping to extract metrics.
# The final result of screen scraping is a file containing data in the following format -
# <EMQ_NODE_IP> <METRIC_NAME> <METRIC_VALUE>
#--------------------------------------------------------------------------------------------

python `dirname $0`/zabbix-emq.py $EMQ_NODE_IP $EMQ_NODE_PORT $DATA_FILE $NAME_IN_ZABBIX

#--------------------------------------------------------------------------------------------
# Check the size of $DATA_FILE. If it is not empty, use zabbix_sender to send data to Zabbix.
#--------------------------------------------------------------------------------------------
if [[ -s $DATA_FILE ]]
then
   /usr/local/bin/zabbix_sender -vv -z 127.0.0.1 -i $DATA_FILE 2>>$LOG_FILE 1>>$LOG_FILE
   echo  -e "Successfully executed $COMMAND_LINE" >>$LOG_FILE
   mv $DATA_FILE $BAK_DATA_FILE
   echo "OK"
else
   echo "Error in executing $COMMAND_LINE" >> $LOG_FILE
   echo "ERROR"
fi
