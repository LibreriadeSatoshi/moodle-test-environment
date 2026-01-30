FROM debian:stable

RUN apt-get update && apt-get install -y \
    postgresql apache2 libapache2-mod-php php-mbstring php-pgsql php-intl \
    php-curl php-xml php-zip php-gd php-soap nano vim git

WORKDIR /root

COPY moodle.conf /etc/apache2/sites-available
COPY scripts/* .

COPY backup ./backup
COPY config.php .
COPY climaintenance.html .

CMD ["bash", "-c", "./install.sh && echo 'Started.' && sleep infinity"]
