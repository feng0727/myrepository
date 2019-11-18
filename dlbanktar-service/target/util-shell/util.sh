#!/bin/bash

CURRENT_DIR=$(cd "$(dirname "$0")"; pwd)
cd $CURRENT_DIR

chmod_dir() {
    # executable file
    EXEC_REG="(.sh|.py|.pyc|.pyo|.lua|.pl|.groovy|.php|.bat|.exe|.ps1|.cmd|.c|.h|.o|.so|.jar)$"
    # config file
    CONF_REG="(.properties|.yaml|.yml|.ini|.conf|.cnf)$"
    # cert file
    CERT_REG="(.pem|.crt|.key|.csr|.p7b|.p7c|.spc|.p12|.pfx|.der|.cer|.ks|.jks|.jceks|.bks|.ubr)$"

    local dir=$1
    if [[ "$dir" =~ "/$" ]] ; then
        dir=${dir%/*}
    fi

    chmod 750 $dir

    IFS=$(echo -en "\n\b")
    for file in `ls -A $dir`
    do
        local path=$dir"/"$file
        if [ -d "$path" ] ; then
            if [[ "$path" =~ "(bin|sbin)$" ]] ; then
                chmod 550 $path/* $path/.*
            else
                chmod 750 $path
            fi
            chmod_dir $path
        else
           suffix=`echo "$file" | awk -F '.' '{print "."$NF}'`
           if [[ "$suffix" =~ $EXEC_REG ]] ; then
              chmod 550 $path
           elif [[ "$suffix" = ".$file" ]] ; then
              chmod 700 $path
           elif [[ "$suffix" =~ $CONF_REG ]] || [[ "$suffix" =~ $CERT_REG ]] ; then
              chmod 600 $path
           else
              parent_dir=$(dirname $path)
              if [[ ! "${parent_dir##*/}" =~ (bin|sbin) ]] ; then
                  chmod 640 $path
              fi
           fi
        fi
    done
}

get_non_system_partition()  {
    declare -A map=()

    fs_list=$(df -kT | grep -vE 'var|usr|boot|tmpfs' | awk '{print $5 "_" $7}' | awk 'NR > 1')
    if [ "${#fs_list[@]}" -le 0 ] ; then
        echo "/opt"
    else
        for fs in $fs_list; do map["${fs%_*}"]=${fs##*_}; done
        keys=(${!map[@]})
        keys=($(for i in "${keys[@]}"; do echo "$i"; done | sort -rn))

        partition=${map[${keys[0]}]}    
        if [ "$partition" = "/" ] ; then
            if [ "${#keys[@]}" -gt 1 ] && [ "${keys[1]}" -gt 31457280 ] ; then
                echo ${map[${keys[1]}]}
            else
                echo "/opt"
            fi
        else
            echo $partition
        fi
    fi
}

get_net_segment() {
    net_seg_arr=()

    nics=$(ls /sys/class/net)
    for nic in $nics
    do
        inet_arr=$(ip addr show $nic | grep 'inet ' | cut -f2 | awk '{ print $2}')
        for inet in ${inet_arr[@]}
        do
            ip=${inet%/*}
            if [ "$ip" != "127.0.0.1" ] && [ "$ip" != "127.0.0.2" ] && [ "$ip" != "localhost" ] ; then
                netmask=$(ipcalc -m $inet | awk -F "=" '{print $2}')
                if [ -n "$netmask" ] ; then
                    network=$(ipcalc -pnbm $ip $netmask | grep -i 'NETWORK' | awk -F "=" '{print $2}')
                    net_seg_arr+=($network/$netmask)
                else
                    # for suse
                    netmask=$(ipcalc -nb $inet | grep -i 'Netmask' | awk  '{print $2}')
            	    network=$(ipcalc -nb $inet | grep -i 'Network' | awk  '{print $2}' | awk -F/ '{print $1}')
		            net_seg_arr+=($network/$netmask)
                fi
            fi
        done
    done

    segment_list=`echo ${net_seg_arr[@]} | tr ' ' ',' | sort -nu`
    echo $segment_list
}

check_stat() {
    soft=$1
    shift
    for p in $@
    do
        port=$p
        for i in {1..15}
        do 
            stat=`ss -anp | grep :$port | grep LISTEN`
            if [ "$stat" != "" ]; then
                echo "$soft $port port is on listening!"
                break;
            fi

            if [ $i -eq 15 ]; then
                echo "$soft $port port isn't on listening, exit!"
                exit 1
            fi

            echo "Detect whether the $soft $port port is on listening, the number of retries: $i"
            sleep 10
        done
        echo
    done
}

usage() {
    echo "usage:"
    echo "    sh check_service optstring parameters"
    echo ""
    echo "Options:"
    echo "    --service-name              service name"
    echo "    --port                      check port list, 8081,8082"
    echo "    --shell                     check shell script"
    echo "    --shell-expect              check restapi"
}

check_service() {
    service_name=""
    check_port=""
    shell_expect=""
    check_cmd=""
    ARGS=`getopt -o h:: --long service-name:,port:,shell:,shell-expect:,help:: -n 'check_service' -- "$@"`  

    if [ $? != 0 ]; then
        usage
        exit 1
    fi

    # note the quotes around `$ARGS': they are essential!  
    eval set -- "$ARGS"  
    while true; do  
        case "$1" in  
            --service-name) 
                service_name=$2 
                shift 2 
                ;;  
            --port) 
                check_port=$2
                shift 2
                ;; 
            --shell) 
                check_cmd=$2 
                shift 2
                ;; 
            --shell-expect) 
                shell_expect=$2
                shift 2
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

    if [ -n "$check_port" ]; then
        port_list=($(echo $check_port|tr "," "\n"))
        check_stat $service_name ${port_list[@]}
        if [ $? -eq 0 ]; then
            echo "$service_name Started!"
        else
            exit 1
        fi
    fi

    if [ -n "$check_cmd" ] ; then
        rm -rf /tmp/check.log
        sh -c "$check_cmd" > /tmp/check.log 2>&1
        if [ $? -eq 0 ] ; then
            if [ -n "$shell_expect" ] ; then
                if [ -f /tmp/check.log ] && [ -n "$(cat /tmp/check.log | grep $shell_expect)" ] ; then
                    echo "$service_name service is available!"
                else
                    rm -rf /tmp/check.log
                    echo "$service_name service is not available!"
                    exit 1
                fi
            else
                echo "$service_name service is available!"
            fi
            rm -rf /tmp/check.log
        else
            rm -rf /tmp/check.log
            echo "$service_name service is not available!"
            exit 1
        fi
    fi
}

exec_service() {
    service_name=$1
    if [ -n $(find /usr/lib/systemd/system/ -name $service_name) ] ; then
        chmod 644 /usr/lib/systemd/system/$service_name*
    else
        echo "systemd service $service_name not found!"
        exit 1
    fi

    for i in {1..3}; do
        systemctl enable $service_name
        if [ "$(systemctl is-enabled $service_name)" == "enabled" ] ; then
            echo "Set $service_name service boot from the successful start!"
            break
        fi
        
        echo "Try setting up the $service_name service again for startup"
        systemctl daemon-reexec
        sleep 1
    done

    systemctl daemon-reload
    systemctl restart $service_name
    if [ $? -ne 0 ] ; then
        echo "$service_name failed to start!"
        exit 1
    fi
}