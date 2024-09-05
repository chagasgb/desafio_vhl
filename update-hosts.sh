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
        echo "[$(date)] Entrada para $hostname já existe." >> /var/log/update_hosts.log
    else
        echo "$ip_address $hostname" >> "$hosts_path"
        echo "[$(date)] Adicionado: $ip_address $hostname" >> /var/log/update_hosts.log
    fi
}

# Criar o arquivo de log se não existir
touch /var/log/update_hosts.log

# Executar a função de atualização
update_hosts

# Saída do container após execução
exit 0