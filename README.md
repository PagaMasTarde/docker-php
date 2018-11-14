# Ubuntu + Apache 2.4 + PHP (7.x)

###Development Image

this is a simple image of docker that contains the typical build of a Web server that uses
Apache 2.4 and PHP 7.1. It's based on Ubuntu:latest.

**Go to the desired branch of the version of PHP you are searching.**

It also brings the typical extensions of PHP and Apache that a normal symfony 4 project
requires.

##### extras:
* npm
* bower
* composer

##### php-extensions:
* Mysqlnd
* Soap
* Sockets
* ftp
* Curl
* Libedit
* Openssl
* Zlib
* Imap
* Kerberos
* Imap-ssl
* Intl
* Pcntl
* Redis
* mysqli
* pdo
* pdo_mysql
* mbstring
* mcrypt
* iconv
* zip
* gd

##### apache document-root:
* working-dir: /var/www
##### docker-compose example for Symfony4 project

here is a docker-compose example, have in mind you need to create docker/vhost inside
your project. You can use the example vhost in this repository under /config/project-name.conf

Keep in mind this is a default VHOST for a symfony 4 project but you should be able to
adapt it to your own needs.

```bash
version: "3.3"
services:
  project-name:
    ports:
      - "8055:80" //On the left the port that will be exposed
    volumes:
      - "./:/var/www/project-name:rw" //Mount files to container
      - "./docker/vhost:/etc/apache2/sites-enabled" //link VHOST to apache
    image: paylater/docker-php71:latest
    working_dir: /var/www/project-name
    environment:
        ENVIRONMENT: dev
```
