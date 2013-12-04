#!/usr/bin/env bash

echo "Update packages"
apt-get update

echo "Preconfigure mysql root password"
debconf-set-selections <<< 'mysql-server-5.5 mysql-server/root_password password root'
debconf-set-selections <<< 'mysql-server-5.5 mysql-server/root_password_again password root'

echo "Install default lamp-server"
apt-get install -y lamp-server^

echo "Link /var/www to /vagrant"
rm -rf /var/www
ln -fs /vagrant /var/www

echo "Set ServerName to localhost"
sh -c 'echo "ServerName localhost" > /etc/apache2/conf.d/name'

echo "Restart server"
service apache2 restart

echo "Lamp server ready!"
echo "------------------"

