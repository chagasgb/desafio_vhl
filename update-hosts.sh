#!/bin/bash

# Verificar se o número correto de argumentos foi fornecido
if [ "$#" -ne 2 ]; then
    echo "Uso: $0 <IP_ADDRESS> <DOMAIN>"
    exit 1
fi

# Obter os argumentos
ip_address=$1
hostname=$2
hosts_path="/etc/hosts"

# Função para atualizar o arquivo hosts
update_hosts() {
    # Verificar se a entrada já existe
    if grep -q "$hostname" "$hosts_path"; then
        echo "Entrada para $hostname já existe."
    else
        # Adicionar entrada ao arquivo /etc/hosts silenciosamente
        echo "$ip_address $hostname"
        echo "Adicionado: $ip_address $hostname"
    fi
}

update_hosts