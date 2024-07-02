FROM ubuntu:latest

LABEL maintainer="manmeet1515@gmail.com"

RUN apt-get update && apt-get install -y apache2

COPY Frontend /var/www/html/

CMD ["apache2ctl", "-D", "FOREGROUND"]

EXPOSE 80


