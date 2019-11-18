#!/bin/bash

CURRENT_DIR=$(cd "$(dirname "$0")"; pwd)
cd $CURRENT_DIR

urlencode() {
    STR=$@
    [ "${STR}x" == "x" ] && { STR="$(cat -)"; }

    echo ${STR} | sed -e 's| |%20|g' \
                      -e 's|!|%21|g' \
                      -e 's|#|%23|g' \
                      -e 's|\$|%24|g' \
                      -e 's|%|%25|g' \
                      -e 's|&|%26|g' \
                      -e "s|'|%27|g" \
                      -e 's|(|%28|g' \
                      -e 's|)|%29|g' \
                      -e 's|*|%2A|g' \
                      -e 's|+|%2B|g' \
                      -e 's|,|%2C|g' \
                      -e 's|/|%2F|g' \
                      -e 's|:|%3A|g' \
                      -e 's|;|%3B|g' \
                      -e 's|=|%3D|g' \
                      -e 's|?|%3F|g' \
                      -e 's|@|%40|g' \
                      -e 's|\[|%5B|g' \
                      -e 's|]|%5D|g' \
                      -e 's|>|%3E|g' \
                      -e 's|<|%3C|g'
}

encrypt() {
    sh -c "</dev/tcp/127.0.0.1/7550" > /dev/null 2>&1
    if [ $? -ne 0 ] ; then
        echo "OMP daemon service unavailable."
        exit 1
    fi
    encryted_text=$(curl -sS "http://127.0.0.1:7550/daemon/api/v2/encryption/encrypt?type=$1&plain_text=$(urlencode $2)&algorithm=$(urlencode $3)")
    echo $encryted_text
}

decrypt() {
    sh -c "</dev/tcp/127.0.0.1/7550" > /dev/null 2>&1
    if [ $? -ne 0 ] ; then
        echo "OMP daemon service unavailable."
        exit 1
    fi
    
    ENCRYPT_REG="^>>>.*<<<$"
    if [[ $1 =~ $ENCRYPT_REG ]] ; then
        plain_text=$(curl -sS "http://127.0.0.1:7550/daemon/api/v2/encryption/decrypt?encrypted_text=$(urlencode $1)")
        echo $plain_text
    else
        echo $1
    fi
}