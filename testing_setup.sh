#!/bin/sh 

set -e 

echo "Configuring .env File"

if [ ! -f .env ]
then 
	echo " -> .env file not found, creating the file."
	touch .env 

	echo "Enter MYSQL Root Password:"
	read ROOT_PW

	echo "Enter Wordpress Database Name:"
	read WP_DATA

	echo "Enter Wordpress Database User:"
	read WP_DATA_USER

	echo "Enter Wordpress Database Password:"
	read WP_DATA_PW

	echo "Enter OSTicket Database Name:"
	read OST_DATA

	echo "Enter OSTicket Database User:"
	read OST_DATA_USER

	echo "Enter OSTicket Database Password:"
	read OST_DATA_PW

	cat > .env <<EOF
ROOT_PW=$ROOT_PW
WP_DATA=$WP_DATA
WP_DATA_USER=$WP_DATA_USER
WP_DATA_PW=$WP_DATA_PW
OST_DATA=$OST_DATA
OST_DATA_USER=$OST_DATA_USER
OST_DATA_PW=$OST_DATA_PW
EOF
fi 

echo "Creating initial sql file" 

cat > init-db.sql <<EOF
CREATE DATABASE IF NOT EXISTS ${WP_DATA} DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS ${OST_DATA} DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${WP_DATA_USER}'@'%' IDENTIFIED BY '${WP_DATA_PW}';
CREATE USER IF NOT EXISTS '${OST_DATA_USER}'@'%' IDENTIFIED BY '${OST_DATA_PW}';
GRANT ALL PRIVILEGES ON ${WP_DATA}.* TO '${WP_DATA_USER}'@'%';
GRANT ALL PRIVILEGES ON ${OST_DATA}.* TO '${OST_DATA_USER}'@'%';
FLUSH PRIVILEGES;
EOF

echo "Downloading Wordpress"

mkdir -p wordpress
curl -sSL https://wordpress.org/latest.tar.gz | tar -xvzf - -C wordpress --strip-components=1

echo "Downloading OSTicket"

mkdir -p OSTicket
curl -sSL -o /tmp/osticket.zip https://github.com/osTicket/osTicket/releases/download/v1.18.3/osTicket-v1.18.3.zip 
unzip -q /tmp/osticket.zip -d /tmp/osticket_extract
cp -a /tmp/osticket_extract/upload/. OSTicket/
rm -f /tmp/osticket.zip 
rm -rf /tmp/osticket_extract

if [ "$(uname)" = "Linux" ] || [ "$(uname)" = "Darwin" ];
then 
	grep -q "wordpress.test" /etc/hosts || echo "127.0.0.1 wordpress.test" | sudo tee -a /etc/hosts
	grep -q "osticket.test" /etc/hosts || echo "127.0.0.1 osticket.test" | sudo tee -a /etc/hosts
else
	echo "You are not on arch btw"
	echo " Add 127.0.0.1 wordpress.test osticket.test in your host file"
fi 

echo "Implementing Docker"

command -v docker >/dev/null 2>&1 || {
	echo "Docker not installed"
	exit 1
}

docker compose up -d --build 


