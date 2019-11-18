#!/bin/bash

CURRENT_DIR=$(cd "$(dirname "$0")"; pwd)
cd $CURRENT_DIR

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

DISCONF_IPS=($(echo $DISCONF_HOST|tr "," "\n"))
for DISCONF_IP in ${DISCONF_IPS[@]};do
    DISCONF_SERVER_ADDR=http://$DISCONF_IP:$DISCONF_PORT
    if [ -z "$DISCONF_HOSTS" ];then
        DISCONF_HOSTS=$DISCONF_IP:$DISCONF_PORT
    else
        DISCONF_HOSTS=${DISCONF_HOSTS},$DISCONF_IP:$DISCONF_PORT
    fi
done

source ./util.sh

INSTALL_DIR=/opt/uyun/dlbanktar/
mkdir -p ${INSTALL_DIR}
\cp -r dlbanktar-service/ ${INSTALL_DIR}
cd ${INSTALL_DIR}/dlbanktar-service/bin
find . -name "*.sh" | xargs chmod +x
JAVA_OPTS=`sh -c "echo '\"-Dbat.developer.mode=false -Ddisconf.enable.remote.conf=true -Ddisconf.app=uyun -Ddisconf.env=local -Ddisconf.version=2_0_0 -Ddisconf.conf_server_host=$DISCONF_HOSTS\"'"`
sh -c "sed -i 's@JAVA_OPTS=.*@JAVA_OPTS=$JAVA_OPTS@' dlbanktar-service.sh"

if [ ! -d $INSTALL_DIR/logs ]; then
    mkdir $INSTALL_DIR/logs
    chown -R $RUNNING_USER:$RUNNING_USER $INSTALL_DIR/logs
    chmod 750 $INSTALL_DIR/logs
else
    chown -R $RUNNING_USER:$RUNNING_USER $INSTALL_DIR/logs
fi

chown -R $RUNNING_USER:$RUNNING_USER /opt/uyun/dlbanktar/dlbanktar-service
chmod 750 /opt/uyun/dlbanktar/dlbanktar-service

setPer(){
    path=$1
    for file in $path*
    do
        if [ ! -d "$file" ];
        then
            if [[ ${file##*.} == 'sh' ]]; then
              chmod 750 "$file"
            else
              chmod 640 "$file"
            fi
        else
            chmod 750 "$file"
            if [ -d "$file" ]; then
              COUNT=$(find "$file" -type f | wc -l)
              if [ $COUNT -ne 0 ];
              then
                   setPer "$file"/
              fi
            fi
        fi
    done
}

setPer '/opt/uyun/dlbanktar/dlbanktar-service'
#chmod 750 /opt/uyun/demo/service

su $RUNNING_USER -c "/opt/uyun/dlbanktar/dlbanktar-service/bin/dlbanktar-service.sh start"
echo "ready to start dlbanktar-service"
check_stat dlbanktar-service 8901
echo "dlbanktar-service start!"





