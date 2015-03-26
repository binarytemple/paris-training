#!/bin/bash

function usage() {
    echo "generate-hosts.sh -t <target host ip> -u <remote user>" >&2
    exit 1
}

while getopts ":t:u:h" opt; do
    case $opt in
    t)
        TARGET=$OPTARG
        echo "Using target $TARGET" >&2
        ;;
    u)
        TARGET_USER=$OPTARG
        echo "Using target user $TARGET_USER" >&2
        ;;
    h)
        usage   
        ;;
    \?)
        echo "Invalid option: -$OPTARG" >&2
        exit 1
        ;;
    :)
        echo "Option -$OPTARG requires an argument" >&2
        exit 1
        ;;
    esac
done

if [[ -z $TARGET || -z $TARGET_USER ]]; then
    usage
fi

cat <<END > ./ansible.hosts
[riak_cluster]
riak-01 ansible_ssh_host=${TARGET} ansible_ssh_port=22 ansible_ssh_user=${TARGET_USER}
END
