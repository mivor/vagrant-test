#!/usr/bin/env bash

echo "Install newrelic daemon"
wget -O - http://download.newrelic.com/548C16BF.gpg | sudo apt-key add -
sudo sh -c 'echo "deb http://apt.newrelic.com/debian/ newrelic non-free" > /etc/apt/sources.list.d/newrelic.list'
sudo apt-get update
sudo apt-get install -q -y newrelic-php5
sudo newrelic-install install

echo "Inserting newrelic license key"
echo "$@"
sed -i -e "s/REPLACE_WITH_REAL_KEY/$@/g" /etc/php5/cli/conf.d/newrelic.ini

echo "Restart server"
sudo service apache2 restart

echo "Newrelic Ready!"
echo "---------------"
