#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Uso: $0 ip dominio"
    exit 1
fi

ip_address=$1
hostname=$2
hosts_path="/etc/hosts"

update_hosts() {
    if grep -q $hostname $hosts_path; then
        echo "Entrada para $hostname já existe."
    else
        echo $ip_address $hostname >> $hosts_path
        echo "Adicionado: $ip_address $hostname"
        sudo systemd-resolve --flush-caches

    fi
}

update_hosts