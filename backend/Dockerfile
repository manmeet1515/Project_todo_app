FROM ubuntu:latest

LABEL maintainer="manmeet1515@gmail.com"

RUN apt-get update && apt-get install -y apache2

COPY Frontend /var/www/html/

ENTRYPOINT ["httpd", "-D", "FOREGROUND"]

EXPOSE 80


