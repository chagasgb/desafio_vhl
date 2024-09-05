# Desafio VHL Sistemas

Neste desafio proposto para o cargo de Assistente de Devops na VHL Sistemas foi solicitado o seguinte ambiente:

- __OpenCMS (com PostgreSQL)__
- __Nginx como proxy-reverso__

A distribuição utilizada nesse laboratório foi o Ubuntu 20.04 (Via WSL 2). <br>

Primeiramente farei toda a instalação do ambiente de forma manual, depois disso será realizado o provisionamento com containers.

### Instalação de dependências e pacotes necessários

1. Atualização do repositório e instalação de dependencias necessárias

```bash
sudo apt update &&
sudo apt install default-jdk -y
```

2. Instalação do Tomcat

```bash
sudo apt install tomcat9 tomcat9-admin tomcat9-common -y
```

3. Instalação do PostgreSQL 

```bash
sudo apt install postgresql postgresql-contrib -y
```

4. Instalação do Nginx

```bash
sudo apt install nginx
```

5. Habilitar stack para inicializar junto com o SO

```bash
sudo systemctl enable tomcat9
sudo systemctl enable postgresql
sudo systemctl enable nginx
```

### Download e setup do OpenCMS

6. Download do OpenCMS (versão 17.0) e descompactação

```bash
wget http://www.opencms.org/downloads/opencms/opencms-17.0.zip
unzip opencms-17.0.zip -d opencms
```

7. Copie o arquivo  `opencms.war` para o diretório do Tomcat

```bash
sudo cp opencms/opencms.war /var/lib/tomcat9/webapps/
```

### Configuração PostgreSQL

8. Acesse o Postgres e defina uma senha para o usuário default. O OpenCMS usará este usuário para criar o banco de dados e as tabelas necessárias.

````bash
#acesso ao banco
$ sudo su - postgres
$ psql
````

```sql
ALTER USER postgres WITH PASSWORD 'pass';
```

9. Baixe o driver JDBC do PostgreSQL e coloque-o no diretório `lib` do Tomcat.

```bash
sudo wget https://jdbc.postgresql.org/download/postgresql-42.2.23.jar -P /var/lib/tomcat9/lib/
```

10. Reinicie o Tomcat para aplicar as alterações

```bash
sudo systemctl restart tomcat9
```

### Configuração do proxy reverso com Nginx

11. Crie um um novo arquivo de configuração para o OpenCMS

```bash
sudo vim /etc/nginx/sites-available/opencms
```

13. Insira as seguintes informações

```nginx
server {
    listen 80;
    server_name localhost;
    
    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Dessa forma, o Nginx irá encaminhar todas as requisões da porta 80 para o Toncat (porta 8080)

14. Ative o arquivo de configuração criando um link simbólico para `sites-enabled`

```bash
sudo ln -s /etc/nginx/sites-available/opencms /etc/nginx/sites-enabled/
```

15. Remova o arquivo default para não interferir no ambiente

```bash
sudo rm -rf /etc/nginx/sites-available/default
```

16. Reinicie o serviço para aplicar as alterações

```bash
sudo systemctl restart nginx
```

Finalizado todo o processo manual, basta acessar o setup do OpemCMS pela URL: **http://localhost/opencms/setup**


## Parte 2 - Subindo o ambiente com Docker Compose

Nessa segunda parte do desafio, farei provisionamento de todo o ambiente com containers utilizando docker-compose para melhor organização.

1. Criação do `Dockerfile` com o OpenCMS

```dockerfile
FROM tomcat:9.0

RUN apt-get update && apt-get install -y wget unzip && \
    wget https://www.opencms.org/en/download/download_versions/downloads/opencms-v11.0.2.zip -O /tmp/opencms.zip && \
    unzip /tmp/opencms.zip -d /usr/local/tomcat/webapps/ && \
    rm /tmp/opencms.zip
    
RUN wget https://jdbc.postgresql.org/download/postgresql-42.2.23.jar -O /usr/local/tomcat/lib/postgresql.jar
EXPOSE 8080
CMD ["catalina.sh", "run"]
```
2. Criação do `docker-compose.yml` contendo os 3 serviços
````yaml
version: '3'

services:
  db:
    image: postgres:12
    container_name: opencms-postgres
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: pass
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  opencms:
    build: .
    container_name: opencms
    environment:
      DB_HOST: db
      DB_PORT: 5432
    volumes:
      - tomcat_data:/usr/local/tomcat/webapps/
    ports:
      - "8080:8080"
    depends_on:
      - db

  nginx:
    image: nginx:latest
    container_name: nginx-proxy
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - opencms

volumes:
  postgres_data:
  tomcat_data:
````
- Os dados do Tomcat e PostgreSQL estão com persistencia de tipo volume, na qual o armazanamento é gerenciado pelo Docker. Diferentemente do arquivo `nginx.conf`, que está como bind mount.

````nginx
events {
    worker_connections 1024;
}

http {
    server {
        listen 80;

        location / {
            proxy_pass http://opencms:8080
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
````
Note que o destino será http://opencms:8080. <br>'opencms' é o nome do serviço do `docker-compose.yml`, que por sua vez é acessivel pelos outros serviços da stack, nesse caso, o Nginx.

3. Dentro do diretorio do projeto, crie a imagem do OpenCMS
````bash
sudo docker-compose build
````
4. Após a criação da imagem, suba os serviços do `docker-compose.yml`
````bash
sudo docker-compose up -d
````
<br>

Agora o OpenCMS estará rodando localmente na URL **http://localhost/opencms/setup**

## Parte 3 - Script para atualização do `hosts`
Nessa última parte do desafio, foi desenvolvido em Bash um script que adiciona uma entrada ao arquivo `/etc/hosts` no Ubuntu.

````bash
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
````
O script verifica se o IP e Dominio já existe e adiciona uma nova entrada.

1. Adicione permissão de execução do script

````bash
chmod +x update-hosts.sh
````

2. Execute da seguinte forma

````bash
./update-hosts.sh 127.0.0.1 opencms.prod
````
Agora o setup OpenCMS estará rodando no host pela URL http://opencms.prod/
