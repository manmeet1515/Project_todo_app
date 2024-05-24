FROM ubuntu
LABEL maintainer="manmeet1515@gmail.com"

WORKDIR /usr/share/nginx/html
RUN apt-get -y update && apt-get -y install nginx

COPY ./default /etc/nginx/sites-available/default
COPY index.html index.html
COPY style.css style.css
COPY script.js script.js

CMD ["/usr/sbin/nginx", "-g", "daemon off;"] 

EXPOSE 80


