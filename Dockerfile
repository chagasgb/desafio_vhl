FROM tomcat:9.0

RUN apt-get update && apt-get install -y wget unzip && \
    wget http://www.opencms.org/downloads/opencms/opencms-17.0.zip -O /tmp/opencms.zip && \
    unzip /tmp/opencms.zip -d /usr/local/tomcat/webapps/ && \
    rm /tmp/opencms.zip
    
RUN wget https://jdbc.postgresql.org/download/postgresql-42.2.23.jar -O /usr/local/tomcat/lib/postgresql.jar

EXPOSE 8080

CMD ["catalina.sh", "run"]