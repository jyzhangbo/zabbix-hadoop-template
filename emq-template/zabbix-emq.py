__author__ = 'zhangbo'

import json
import urllib
import logging
import sys
import time
from urllib import request

# ---------------------------------
# Generate URL
# ---------------------------------
# This function converts the servername to URL which we need to query.


def get_url(server_name, listen_port):

    if int(listen_port) < 0:
        print ("Invalid Port")
        exit()

    if not server_name:
        print("Pass valid Hostname")
        exit()

    URL = "http://"+server_name+":" + \
        str(listen_port)+"/api/v2/monitoring/nodes"
    return URL


# ---------------------------------
# Load URL
# ---------------------------------
def load_url_as_dictionary(url):

    req = request.Request(url)
    req.add_header("Authorization","Basic YWRtaW46cHVibGlj")
    return json.load(request.urlopen(req))


def json_processing(server_name, listen_port):

    namenode_dict = {}

    node_json = load_url_as_dictionary(
        get_url(server_name, listen_port))

    nodeinfo = node_json['result']
    namenode_dict['nodes'] = len(nodeinfo)
    running_node = 0
    dead_node = 0
    nodes_name = ''
    for node in nodeinfo:
        if node['node_status'] =='Running':
            running_node = running_node + 1
            nodes_name = nodes_name + node['name'] + ';'
        else:
            dead_node = dead_node + 1

    namenode_dict['nodes_running'] = running_node
    namenode_dict['nodes_dead'] = dead_node
    return namenode_dict


def write_data_to_file(json, file_path, nodename_in_zabbix):
    txt_file = open(file_path, 'w+')
    for keys in json:
        txt_file.writelines(nodename_in_zabbix + ' ' +
                            str(keys) + ' ' + str(json[keys]) + '\n')


def usage():
    print("Usage: emq_node_id = %s; emq_node_port = %s; ")


if __name__ == '__main__':

    logging.basicConfig(level=logging.INFO)
    if len(sys.argv) == 4:
        emq_node_ip = sys.argv[1]
        emq_node_port = sys.argv[2]
        file_path = sys.argv[3]
        nodename_in_zabbix = sys.argv[4]

        json_processed = json_processing(emq_node_ip,emq_node_port)
        write_data_to_file(json_processed, file_path, nodename_in_zabbix)

    else:
        usage()
