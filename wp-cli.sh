#!/usr/bin/env bash

echo "Create mysql user and database for wordpress"
mysql -uroot -proot -e "CREATE DATABASE wordpress"
mysql -uroot -proot -e "GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpress'@'localhost' IDENTIFIED BY 'dev'"
mysql -uroot -proot -e "FLUSH PRIVILEGES"

echo "Install wp-cli dependencies"
echo "------------------------------"
sudo apt-get update

echo "Install curl & git"
sudo apt-get install -q -y curl git

echo "Install wp-cli"
curl https://raw.github.com/wp-cli/wp-cli.github.com/master/installer.sh | bash

echo "Add .bashrc config for wp-cli"
echo '# WP-CLI directory' >> /home/vagrant/.bashrc
echo 'export PATH=/home/vagrant/.wp-cli/bin:$PATH' >> /home/vagrant/.bashrc
echo '# WP-CLI Bash completions' >> /home/vagrant/.bashrc
echo 'source $HOME/.wp-cli/vendor/wp-cli/wp-cli/utils/wp-completion.bash' >> /home/vagrant/.bashrc
source /home/vagrant/.bashrc

echo "Download wordpress"
cd /vagrant
wget http://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz
cp /vagrant/wordpress/index.php /vagrant/index.php
sed -i -e "s/\.\/wp-blog-header/\.\/wordpress\/wp-blog-header/g" /vagrant/index.php

echo "Create wp-config.php"
cd /vagrant/wordpress
/home/vagrant/.wp-cli/bin/wp core config --dbname=wordpress --dbuser=wordpress --dbpass=dev --extra-php <<PHP
define( 'WP_DEBUG', true );
define( 'WP_DEBUG_LOG', true );
PHP

echo "Install wordpess at 127.0.0.1:$1"
/home/vagrant/.wp-cli/bin/wp core install --url="http://127.0.0.1:$1/wordpress" --title="local dev" --admin_email="mivor20@gmail.com" --admin_password="dev"

echo "Wordpres Ready!"
echo "---------------"
