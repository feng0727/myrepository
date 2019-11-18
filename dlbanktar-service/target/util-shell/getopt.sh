#!/bin/bash

CURRENT_DIR=$(cd "$(dirname "$0")"; pwd)
cd $CURRENT_DIR

source ./crypt.sh

INSTALL_ROLE=single
LOCAL_IP=$(ip addr | grep 'scope global' | awk '{print $2}' | awk -F '/' '{print $1}' | head -1)

#disconf基本信息
DISCONF_PORT=8081
DISCONF_VERSION=2_0_0
DISCONF_APP_UYUN=uyun
DISCONF_ENV=local

RUNNING_USER=root

# 解析common.properties文件指定key的值
getConfItem() {
    conf_item=$(cat common.properties | grep $1=)
    echo ${conf_item/$1=/}
}
 
# 解析result文件json是否返回true
checkResult() {
    loginResult=$(cat result | ./jq '.success')
    if [ "$loginResult" != "\"true\"" ]; then
        echo "$1"
        exit 1
    else
        echo "$2"
    fi
}

# 上传配置文件到disconf tenant
upload_file() {
    uyun_config_file=$1
    uyun_key=${uyun_config_file##*/}
    curl -b cookies -c cookies -sS "$CONF_LIST_URL?appId=$UYUN_APP_ID&envId=$ENV_ID&version=$DISCONF_VERSION" | grep -v err_no > result
    CONFIG_ID=$(cat result | ./jq ".page.result[] | select(.key == \"$uyun_key\") | .configId")
    
    if [ -n "$CONFIG_ID" ]; then
        echo "Clear the disconf old configuration file"
        curl -b cookies -c cookies -X DELETE -sS "$FILE_DEL_URL/$CONFIG_ID"
    fi

    UPLOAD_URL="$FILE_UPLOAD_URL?appId=$UYUN_APP_ID&envId=$ENV_ID&version=$DISCONF_VERSION"
    curl -b cookies -c cookies -sS -F "myfilerar=@$uyun_config_file" $UPLOAD_URL | grep -v err_no &> result
    checkResult "$uyun_config_file uploaded failed" "$uyun_config_file uploaded successfully"
}

# 上传配置文件到disconf tenant
upload_disconf_file() {
    upload_url=$3
    if [ -n "$1" ]; then
        echo "Clear the disconf old configuration file"
        curl -b cookies -c cookies -X DELETE -sS "$FILE_DEL_URL/$1" | grep -v err_no &> /dev/null
    fi
    curl -b cookies -c cookies -sS -F "myfilerar=@$2" $upload_url | grep -v err_no &> result
    checkResult "$2 uploaded failed" "$2 uploaded successfully"
}

# 创建并获取租户app ID
get_disconf_appId() {
    app_name=$1
    app_id=$(cat result | ./jq ".page.result[] | select(.name == \"$app_name\") | .id")
    if [ -z "$app_id" ]; then
        curl -b cookies -c cookies -sS $APP_CREATE_URL --data "app=$app_name&desc=$app_name" | grep -v err_no > /dev/null
        curl -b cookies -c cookies -sS $APP_LIST_URL | grep -v err_no > result
        app_id=$(cat result | ./jq ".page.result[] | select(.name == \"$app_name\") | .id")
    fi
    echo $app_id
}

println() {
    echo "--------------------req parameters-----------------------------"
    echo "DISCONF_VERSION=$DISCONF_VERSION"
    echo "DISCONF_APP_UYUN=$DISCONF_APP_UYUN"
    echo "DISCONF_ENV=$DISCONF_ENV"
    echo "DISCONF_PORT=$DISCONF_PORT"
    echo "DISCONF_HOST=$DISCONF_HOST"
    echo "DISCONF_USER=$DISCONF_USER"
    echo "DISCONF_PASS=$DISCONF_PASS"
    echo "LOCAL_IP=$LOCAL_IP"
    echo "--------------------req parameters-----------------------------"
}

load_common_item() {
    if [ -z "$DISCONF_HOST" ];then
        echo "Please enter disconf"
        exit 1
    fi
    
    DISCONF_IPS=($(echo $DISCONF_HOST|tr "," "\n"))
    for DISCONF_IP in ${DISCONF_IPS[@]}; do
        if [ -z "$DISCONF_HOSTS" ];then
            DISCONF_HOSTS=$DISCONF_IP:$DISCONF_PORT
        else
            DISCONF_HOSTS=${DISCONF_HOSTS},$DISCONF_IP:$DISCONF_PORT
        fi
    done
    for DISCONF_IP in ${DISCONF_IPS[@]}; do
        DISCONF_SERVER_ADDR=http://$DISCONF_IP:$DISCONF_PORT

        #disconf api列表
        LOGIN_URL=$DISCONF_SERVER_ADDR/api/account/signin
        APP_CREATE_URL=$DISCONF_SERVER_ADDR/api/app
        APP_LIST_URL=$DISCONF_SERVER_ADDR/api/app/list
        ENV_LIST_URL=$DISCONF_SERVER_ADDR/api/env/list
        FILE_DOWNLOAD_URL=$DISCONF_SERVER_ADDR/api/web/config/download/
        FILE_UPLOAD_URL=$DISCONF_SERVER_ADDR/api/web/config/file
        CONF_LIST_URL=$DISCONF_SERVER_ADDR/api/web/config/simple/list
        FILE_DEL_URL=$DISCONF_SERVER_ADDR/api/web/config

        #disconf登录
        curl -b cookies -c cookies --connect-timeout 30 -sS $LOGIN_URL --data "name=$DISCONF_USER&password=$(decrypt $DISCONF_PASS)&remember=0" -o result
        loginResult=$(cat result | ./jq '.success')
        if [ "$loginResult" == "\"true\"" ]; then
            echo "Disconf login successful"
            login_result=true
            break
        else
            login_result=false
        fi
    done
    
    if [ "$login_result" == "false" ];then
        echo "Disconf login failed!"
        exit 1
    fi

    # 获取app列表
    curl -b cookies -c cookies -sS $APP_LIST_URL | grep -v err_no > result

    # 获取uyun appId
    UYUN_APP_ID=$(get_disconf_appId $DISCONF_APP_UYUN)

    #获取envId
    curl -b cookies -c cookies -sS $ENV_LIST_URL | grep -v err_no > result
    ENV_ID=$(cat result | ./jq '.page.result[] | select(.name == "local") | .id')

    # 获取common.properties configId配置项
    curl -b cookies -c cookies -sS "$CONF_LIST_URL?appId=$UYUN_APP_ID&envId=$ENV_ID&version=$DISCONF_VERSION" | grep -v err_no > result
    CONFIG_ID=$(cat result | ./jq '.page.result[] | select(.key == "common.properties") | .configId')

    if [ -z "$CONFIG_ID" ]; then
        echo "Disconf app (uyun) did not find common.properties configuration, please configure!"
        exit -1
    fi

    #下载common.properties文件到当前目录
    curl -b cookies -c cookies -o common.properties -sS "$FILE_DOWNLOAD_URL/$CONFIG_ID"
    MYSQL_HOST=$(getConfItem "mysql.ip")
    MYSQL_PORT=$(getConfItem "mysql.port")
    MYSQL_USER=$(getConfItem "mysql.username")
    MYSQL_PASS=$(getConfItem "mysql.password")

    MQ_URL=$(getConfItem "mq.brokerURL")?startupMaxReconnectAttempts=2
    MQ_USERNAME=$(getConfItem "mq.userName")
    MQ_PASSWORD=$(getConfItem "mq.password")

    ZK_URL=$(getConfItem "zk.url")

    UYUN_LANG=$(getConfItem "uyun.lang")

    MONGODB_HOSTS=$(getConfItem "mongodb.hosts")
    MONGODB_PASS=$(getConfItem "mongodb.password")
    MONGODB_USER=$(getConfItem "mongodb.username")
    MONGODB_CREDENTIALS=$(getConfItem "mongodb.credentials")

    REDIS_MASTER=$(getConfItem "redis.master")
    REDIS_PASSWD=$(getConfItem "redis.password")
    REDIS_NODES=$(getConfItem "redis.sentinel.nodes")

    ORIENTDB_HOSTS=$(getConfItem "orientdb.hosts")
    ORIENTDB_USER=$(getConfItem "orientdb.username")
    ORIENTDB_PASS=$(getConfItem "orientdb.password")

    CASSANDRA_CLUSTER_NAME=$(getConfItem "cassandra.cluster.name")
    CASSANDRA_HOSTS=$(getConfItem "cassandra.hosts")
    CASSANDRA_USER=$(getConfItem "cassandra.username")
    CASSANDRA_PASS=$(getConfItem "cassandra.password")

    TSCACHED_HTTP_HOSTS=$(getConfItem "tscached.http.hosts")
    KAIROSDB_HTTP_HOSTS=$(getConfItem "kairosdb.http.hosts")
    KAIROSDB_TELNET_HOSTS=$(getConfItem "kairosdb.telnet.hosts")

    ES_NAME=$(getConfItem "elasticsearch.cluster.name")
    ES_HOSTS=$(getConfItem "elasticsearch.hosts")
    ES_HTTP_HOST=$(getConfItem "elasticsearch.http.hosts")

    for LINE in `cat common.properties`
    do
        KEY=$(echo $LINE | awk -F '=' '{print $1}')
        VALUE=${LINE/$KEY=/}
        #echo "$KEY=$VALUE"
        
        var=`echo ${KEY//./_} | tr a-z A-Z`
        val=$(decrypt $VALUE)
        eval "${var}='${val}'"
    done
}

usage() {
    echo "usage:"
    echo "    sh install.sh optstring parameters"
    echo "    sh install.sh [options] [--] optstring parameters"
    echo "    sh install.sh [options] -o|--options optstring [options] [--] parameters"
    echo ""
    echo "Options:"
    echo "    --security-level                   security level(medium | high)"
    echo "    --disconf-host                     disconf ip list, e.g: 10.1.241.2"
    echo "    --disconf-port                     disconf port, default: 8081"
    echo "    --disconf-user                     disconf user, default: admin"
    echo "    --disconf-passwd                   disconf passwd, default: admin"
    echo "    --local-ip                         local node ip, e.g: 10.1.241.3"
    echo "    --remote-ips                       remote node ip list, e.g: 10.1.241.4,10.1.241.5"
    echo "    --install-role                     install role: single, master, slave, default: single"
    echo "    -h, --help                         help"
}

ARGS=`getopt -o h:: --long security-level:,disconf-host:,disconf-port:,disconf-user:,disconf-passwd:,local-ip:,remote-ips:,install-role:,running-user:,help:: -n 'install.sh' -- "$@"`

if [ $? != 0 ]; then
    usage
    exit 1
fi

# note the quotes around `$ARGS': they are essential!  
#set 会重新排列参数的顺序，也就是改变$1,$2...$n的值，这些值在getopt中重新排列过了  
eval set -- "$ARGS"  

#经过getopt的处理，下面处理具体选项。  
while true ; do  
    case "$1" in
        --security-level)
            SECURITY_LEVEL=$2
            shift 2
            ;;
        --disconf-host) 
            DISCONF_HOST=$2 
            shift 2 
            ;;  
        --disconf-port) 
            DISCONF_PORT=$2
            shift 2
            ;; 
        --disconf-user) 
            DISCONF_USER=$2 
            shift 2
            ;; 
        --disconf-passwd) 
            DISCONF_PASS=$2
            shift 2
            ;; 
        --local-ip)
            LOCAL_IP=$2
            shift 2
            ;;    
        --remote-ips)
            REMOTE_IPS=$2
            shift 2
            ;;  
        --install-role)
            INSTALL_ROLE=$2
            shift 2
            ;;
        --running-user)
            RUNNING_USER=$2
            shift 2
            ;;  
        -h|--help)
            usage
            exit 1
            ;;
        --)
            break 
            ;; 
        *) 
            echo "internal error!" ; 
            exit 1 
            ;;  
    esac  
done  