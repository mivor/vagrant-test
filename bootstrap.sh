#!/usr/bin/env bash

MACHINE_NAME="$1"
IS_PACKAGES_UPDATED=""
#
# Tasks
#

## Bootstrap

change_ps() {
    sed -i -e 's/#force_color_prompt=/force_color_prompt=/g' /home/vagrant/.bashrc
    sed -i -e 's/\[\\033\[01;32m\\]\\u@\\h\\\[\\033\[00m\\]:\\\[\\033\[01;34m\\]/\[\\033\[36m\\]\\u\\\[\\033\[00m\\]@\\[\\033\[36m\\]\\h\\\[\\033\[00m\\]:\\\[\\033\[33m\\]/g' /home/vagrant/.bashrc
}

fix_tty() {
    sed -i -e 's/^mesg n/tty -s \&\& mesg n/g' /root/.profile
}

update_packages() {
    if [[ "$IS_PACKAGES_UPDATED" == "" ]]; then
        apt-get update -qq
        if [[ "$?" == 0 ]]; then
            IS_PACKAGES_UPDATED="true"
            return 0;
        fi
        return 1;
    fi
    return 0;
}

dist_upgrade() {
    by_id='/dev/disk/by-id/'
    hdd_id=$(ls -la $by_id | grep -Poe 'ata.*(?= -)(?!.*\d$)')
    hdd_id="$by_id$hdd_id"
    debconf-set-selections <<< "grub-pc grub-pc/install_devices multiselect $hdd_id"
    debconf-set-selections <<< "grub-pc grub-pc/install_devices_disks_changed multiselect $hdd_id"
    apt-get -y -q dist-upgrade
}

## LAMP server

set_mysql_root_pass() {
    debconf-set-selections <<< "mysql-server-5.5 mysql-server/root_password password $1"
    debconf-set-selections <<< "mysql-server-5.5 mysql-server/root_password_again password $1"
}

install_lamp_server() {
    apt-get install -y -q lamp-server^
}

set_web_location() {
    echo "change web location"
    # rm -rf /var/www
    # ln -fs /vagrant /var/www
}

set_server_name() {
    sh -c 'echo "ServerName localhost" > /etc/apache2/conf.d/name'
}

restart_apache() {
    service apache2 restart
}

phpmyadmin_install() {
    # TODO
    echo "TODO PHPMYADMIN"
}

## NewRelic

install_newrelic() {
    wget -O - http://download.newrelic.com/548C16BF.gpg | apt-key add -
    echo "deb http://apt.newrelic.com/debian/ newrelic non-free" > /etc/apt/sources.list.d/newrelic.list
    apt-get update -qq
    apt-get install -q -y newrelic-php5
    newrelic-install install
}

set_newrelic_license_key() {
    sed -i -e "s/REPLACE_WITH_REAL_KEY/$@/g" /etc/php5/cli/conf.d/newrelic.ini
}

## Wordpress

set_wp_db_user() { #db user pass
    local WP_DB="$1"
    local WP_USER="$2"
    local WP_PASS="$3"
    mysql -uroot -proot -e "CREATE DATABASE $WP_DB"
    mysql -uroot -proot -e "GRANT ALL PRIVILEGES ON $WP_DB.* TO '$WP_USER'@'localhost' IDENTIFIED BY '$WP_PASS'"
    mysql -uroot -proot -e "FLUSH PRIVILEGES"
}

install_git() {
    apt-get install -q -y git
}

install_curl() {
    apt-get install -q -y curl
}

install_wp_cli() {
    # todo user
    su vagrant -c "curl https://raw.github.com/wp-cli/wp-cli.github.com/master/installer.sh | bash"
}

set_wp_cli_bashrc() {
    echo '# WP-CLI directory' >> /home/vagrant/.bashrc
    echo 'export PATH=/home/vagrant/.wp-cli/bin:$PATH' >> /home/vagrant/.bashrc
    echo '# WP-CLI Bash completions' >> /home/vagrant/.bashrc
    echo 'source /home/vagrant/.wp-cli/vendor/wp-cli/wp-cli/utils/wp-completion.bash' >> /home/vagrant/.bashrc
}

download_wordpress() {
    cd /vagrant
    curl -O http://wordpress.org/latest.tar.gz
    tar -xzf latest.tar.gz
    cp /vagrant/wordpress/index.php /vagrant/index.php
    sed -i -e "s/\.\/wp-blog-header/\.\/wordpress\/wp-blog-header/g" /vagrant/index.php
}

set_wp_config() { #db user pass
    local WP_DB="$1"
    local WP_USER="$2"
    local WP_PASS="$3"
    cd /vagrant/wordpress
    /home/vagrant/.wp-cli/bin/wp core config --dbname=$WP_DB --dbuser=$WP_USER --dbpass=$WP_PASS --extra-php <<PHP
define( 'WP_DEBUG', true );
define( 'WP_DEBUG_LOG', true );
PHP
}

install_wordpress() { #ip [192.168.200.]<$1>
    /home/vagrant/.wp-cli/bin/wp core install --url=http://192.168.200.$1/ --title="local dev" --admin_email=mivor20@gmail.com --admin_password=dev
}


# NOT NEEDED USE: config.vm.hostname = "hostname"
# change_hostname() {
#    sh -c "echo $1 > /etc/hostname"
# }

test_echo() {
    printf "Some really complicated function herer\n"
    printf "WORKING \"dev\" \"$1\" $3 $2\n"
}

#
# Logging Functions
#

logger() { # ?m MSG func params
    # check if we expect output from command
    if [[ "$1" == "m" ]]; then
        IS_MULTI_LINE="true"
        shift
    fi
    # assign message to be printed
    local MSG="[$MACHINE_NAME] $1..."
    shift
    # print newline if multi line command
    if [[ "$IS_MULTI_LINE" == "" ]]; then
        printf "$MSG"
    else
        printf "$MSG\n"
    fi
    # execute command with leftover args
    "$@"
    # check comands error STATUS
    if [[ "$?" == 0 ]]; then
        STATUS="DONE"
    else
        STATUS="ERROR"
    fi
    # display error STATUS
    if [[ "$IS_MULTI_LINE" == "" ]]; then
        printf "DONE\n"
    else
        printf "$MSG$STATUS\n"
    fi
}

list_finished() { # list_name
    printf "===================\n"
    printf "$1 Finished!\n"
    printf "===================\n"
}

#
# TaskLists
#

bootstrap() {
    # logger "m" "Testing empty func" test_echo
    # logger "Testing echo" test_echo "$@"
    logger "Changing PS1" change_ps
    logger "Fixing: 'stdin: is not a tty'" fix_tty
    logger "Updating packages" update_packages
    logger 'm' "Upgrading distro" dist_upgrade

    list_finished "Bootstrap"
}

lamp_server() {
    # logger "Updating packages" update_packages
    # logger "Preconfiguring mysql install" set_mysql_root_pass 'root'
    # logger 'm' "Installing default lamp-server" install_lamp_server
    # logger "Changing default web server location" set_web_location
    # logger 'm' "Setting ServerName to localhost" set_server_name
    logger 'm' "Restarting apache web server" restart_apache

    list_finished "Lamp Server"
}

newrelic_daemon() {
    logger 'm' "Installing newrelic daemon" install_newrelic
    logger 'm' "Inserting newrelic license key" set_newrelic_license_key 'KEYKEYlicKEYlicKEY'
    logger 'm' "Restarting apache web server" restart_apache

    list_finished "Newrelic Daemon"
}

Wordpress() {
    logger 'm' "Creating mysql user & db for wordpress" set_wp_db_user 'wordpress' 'wordpress' 'dev'
    logger 'm' "Updating packages" update_packages
    logger 'm' "Installing git" install_git
    logger 'm' "Installing curl" install_curl
    logger 'm' "Installing wp-cli" install_wp_cli
    logger 'm' "Adding .bashrc config for wp-cli" set_wp_cli_bashrc
    logger 'm' "Downloading wordpress" download_wordpress
    logger 'm' "Creating wp-config.php" set_wp_config 'wordpress' 'wordpress' 'dev'
    logger 'm' "Installing WordPress" install_wordpress '10'

    list_finished "WordPress"
}

main() {
    lamp_server
}

main
