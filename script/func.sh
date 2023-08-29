#!/bin/bash
# Program Name: func.sh
# Author name: Wenhao Fang
# Date Created: Aug 23rd 2023
# Date updated:
# Description of the script: Store functions

# whether to continue installation
is_continue() {
    local P_STEP=$1
    local P_LAST_KEY=$2

    if [ $P_LAST_KEY != 0 ]; then
        local P_KEY=-1
        while [ $P_KEY != 1 ] && [ $P_KEY != 0 ]; do
            echo -e "\n$(date +'%Y-%m-%d %R') Next step: ${P_STEP}"
            echo -e "Do you want to continue or cancel? Enter '1' to continue, '0' to cancel."
            read P_KEY
        done
        return $P_KEY
    fi
    return 0
}

## Updates OS
update_os() {
    yes | sudo apt-get update # update the package on Linux system.
    # sudo apt-get upgrade # downloads and installs the updates for each outdated package and dependency
}

# Install and configure MySQL
setup_mysql() {

    P_USER=$1
    P_PWD=$2
    P_DB_NAME=$3

    ###########################################################
    ## Install MySQL
    ###########################################################
    echo -e "\n$(date +'%Y-%m-%d %R') Installing MySQL related packages..."
    sudo apt-get install mysql-server
    sudo systemctl start mysql

    echo -e "\n$(date +'%Y-%m-%d %R') Installing MySQL related packages..."
    sudo apt-get install python3-dev default-libmysqlclient-dev build-essential pkg-config

    ###########################################################
    ## Configure MySQL
    ###########################################################
    # sudo mysql_secure_installation # may create issue

    sudo systemctl start mysql
    echo -e "\n$(date +'%Y-%m-%d %R') Check Mysql status:"
    systemctl status mysql.service
    # read -p "Press Enter to continue..."

    echo -e "\n$(date +'%Y-%m-%d %R') Create user."
    sudo mysql -u root -e "CREATE USER '${P_USER}'@'localhost' IDENTIFIED BY '${P_PWD}';"

    echo -e "\n$(date +'%Y-%m-%d %R') Grant privileges."
    sudo mysql -u root -e "GRANT CREATE, ALTER, DROP, INSERT, UPDATE, INDEX, DELETE, SELECT, REFERENCES, RELOAD on *.* TO '${P_USER}'@'localhost' WITH GRANT OPTION;"
    sudo mysql -u root -e "FLUSH PRIVILEGES;"

    echo -e "\n$(date +'%Y-%m-%d %R') Create database."
    sudo mysql -u$P_USER -p$P_PWD -e "CREATE DATABASE ${P_DB_NAME};"

    sudo mysql -u$P_USER -p$P_PWD -e 'show databases;'
    # read -p "Press Enter to continue..."
}

# Establish virtual environment
setup_venv() {
    echo -e "\n$(date +'%Y-%m-%d %R') Installing venv package..."
    sudo apt-get install python3-venv # Install pip package
    # sudo apt-get install virtualenv # Install pip package
    echo -e "$(date +'%Y-%m-%d %R') Venv package installed."

    echo -e "\n$(date +'%Y-%m-%d %R') Creating virtual environment..."
    cd ~
    sudo rm -rf env     # remove existing venv
    python3 -m venv env # Creates virtual environment
    echo -e "$(date +'%Y-%m-%d %R') Virtual environment Created."
}

# Download codes from github
load_code() {
    # Accepts arguments
    P_PROJECT_NAME=$1
    P_GITHUB_URL=$2

    ###########################################################
    ## Download codes from github
    ###########################################################
    cd ~
    sudo rm -rf ~/${P_PROJECT_NAME} # remove the exsting directory
    git clone $P_GITHUB_URL         # clone codes from github
}

# Create .env file within project dir
create_env_file() {

    P_PROJECT_NAME=$1
    P_HOST_IP=$2
    P_DB_NAME=$3
    P_USER=$4
    P_PWD=$5

    ###########################################################
    ## Djnago project configuration
    ###########################################################
    cd ~

    env_file=~/${P_PROJECT_NAME}/${P_PROJECT_NAME}/${P_PROJECT_NAME}/.env
    sudo bash -c "sudo cat >$env_file <<ENV
DEBUG=False
ALLOWED_HOSTS=${P_HOST_IP}
MYSQL_DATABASE_NAME=${P_DB_NAME}
MYSQL_USERNAME=${P_USER}
MYSQL_PASSWORD=${P_PWD}
MYSQL_HOST=localhost
MYSQL_PORT=3306
ENV"

    echo -e $"\nThe .env file has been created. (Path: $env_file)"
    echo -e $"\nPress Enter to continue..."
}

# Install packages within venv and test app on 8000
update_venv_package() {

    P_PROJECT_NAME=$1
    P_MIGRATE_APP=$2

    ###########################################################
    ## Update packages within venv
    ###########################################################
    cd ~
    source env/bin/activate # activate venv

    echo -e "\n$(date +'%Y-%m-%d %R') Installing packages within virtual environment..."
    pip install -r ~/${P_PROJECT_NAME}/requirements.txt
    pip list

    ###########################################################
    ## Migrate App
    ###########################################################
    python3 ~/${P_PROJECT_NAME}/${P_PROJECT_NAME}/manage.py makemigrations
    python3 ~/${P_PROJECT_NAME}/${P_PROJECT_NAME}/manage.py migrate
    deactivate

    # read -p "Press Enter to continue..."

}

# test app on 8000
test_app() {
    P_PROJECT_NAME=$1
    P_MIGRATE_APP=$2

    cd ~
    source env/bin/activate # activate venv

    ###########################################################
    ## Migrate App
    ###########################################################
    python3 ~/${P_PROJECT_NAME}/${P_PROJECT_NAME}/manage.py makemigrations
    python3 ~/${P_PROJECT_NAME}/${P_PROJECT_NAME}/manage.py migrate

    ###########################################################
    ## Test App
    ###########################################################
    echo -e "\n$(date +'%Y-%m-%d %R') Testing on 8000 (Crtl+C to quit testing)..."
    python3 ~/${P_PROJECT_NAME}/${P_PROJECT_NAME}/manage.py runserver 0.0.0.0:8000
    deactivate
}

# Install and configure Gunicorn
setup_gunicorn() {

    P_PROJECT_NAME=$1

    ###########################################################
    ## Install gunicorn in venv
    ###########################################################
    echo -e "$(date +'%Y-%m-%d %R') Installing gunicorn..."
    cd ~
    source env/bin/activate # activate venv
    pip install gunicorn    # install gunicorn

    deactivate # deactivate venv

    ###########################################################
    ## Configuration gunicorn
    ## Configuration gunicorn.socket
    ###########################################################

    echo -e "$(date +'%Y-%m-%d %R') Create gunicorn socket conf file."
    socket_conf=/etc/systemd/system/gunicorn.socket

    sudo bash -c "sudo cat >$socket_conf <<SOCK
[Unit]
Description=gunicorn socket

[Socket]
ListenStream=/run/gunicorn.sock

[Install]
WantedBy=sockets.target
SOCK"

    ###########################################################
    ## Configuration gunicorn.service
    ###########################################################
    echo -e "$(date +'%Y-%m-%d %R') Create gunicorn service conf file"
    service_conf=/etc/systemd/system/gunicorn.service

    sudo bash -c "sudo cat >$service_conf <<SERVICE
[Unit]
Description=gunicorn daemon
Requires=gunicorn.socket
After=network.target

[Service]
User=root
Group=www-data 
WorkingDirectory=/home/ubuntu/${P_PROJECT_NAME}/${P_PROJECT_NAME}
ExecStart=/home/ubuntu/env/bin/gunicorn \
    --access-logfile - \
    --workers 3 \
    --bind unix:/run/gunicorn.sock \
    ${P_PROJECT_NAME}.wsgi:application

[Install]
WantedBy=multi-user.target
SERVICE"

    ###########################################################
    ## Apply gunicorn configuration
    ###########################################################
    echo -e "$(date +'%Y-%m-%d %R') Apply gunicorn configuration."
    sudo systemctl daemon-reload          # reload daemon
    sudo systemctl start gunicorn.socket  # Start gunicorn
    sudo systemctl enable gunicorn.socket # enable on boots
    sudo systemctl restart gunicorn       # restart gunicorn
}

# Install and configure Nginx
setup_nginx() {

    # Accepts arguments
    P_PROJECT_NAME=$1
    P_HOST_IP=$2

    ###########################################################
    ## Configuration nginx
    ###########################################################
    echo -e "$(date +'%Y-%m-%d %R') Installing nginx package..."
    sudo apt-get install nginx # install nginx
    echo -e "$(date +'%Y-%m-%d %R') Nginx package installed."

    echo -e "$(date +'%Y-%m-%d %R') Configure nginx."
    # overwrites user
    nginx_conf=/etc/nginx/nginx.conf
    sudo sed -i '1cuser root;' $nginx_conf

    # create conf file
    django_conf=/etc/nginx/sites-available/django.conf
    sudo bash -c "cat >$django_conf <<DJANGO_CONF
server {
listen 80;
server_name ${P_HOST_IP};
location = /favicon.ico { access_log off; log_not_found off; }
location /static/ {
    root /home/ubuntu/${P_PROJECT_NAME}/${P_PROJECT_NAME};
}

location /media/ {
    root /home/ubuntu/${P_PROJECT_NAME}/${P_PROJECT_NAME};
}

location / {
    include proxy_params;
    proxy_pass http://unix:/run/gunicorn.sock;
}
}
DJANGO_CONF"

    #  Creat link in sites-enabled directory
    sudo ln -sf /etc/nginx/sites-available/django.conf /etc/nginx/sites-enabled

    # restart nginx
    echo -e "$(date +'%Y-%m-%d %R') Restart nignx."
    sudo nginx -t
    sudo systemctl restart nginx
    # read -p "Press Enter to continue..."
}

# Install and configure Supervisor
setup_supervisor() {
    # Accepts arguments
    P_PROJECT_NAME=$1

    ###########################################################
    ## Configuration supervisor
    ###########################################################
    echo -e "\n$(date +'%Y-%m-%d %R') Installing supervisor package..."
    sudo apt-get install supervisor # install supervisor
    echo -e "$(date +'%Y-%m-%d %R') Supervisor package installed."

    echo -e "$(date +'%Y-%m-%d %R') Configure supervisor for gunicorn"
    sudo mkdir -p /var/log/gunicorn # create directory for logging

    supervisor_gunicorn=/etc/supervisor/conf.d/gunicorn.conf # create configuration file
    sudo bash -c "cat >$supervisor_gunicorn <<SUP_GUN
[program:gunicorn]
    directory=/home/ubuntu/${P_PROJECT_NAME}/${P_PROJECT_NAME}
    command=/home/ubuntu/env/bin/gunicorn --workers 3 --bind unix:/run/gunicorn.sock  ${P_PROJECT_NAME}.wsgi:application
    autostart=true
    autorestart=true
    stderr_logfile=/var/log/gunicorn/gunicorn.err.log
    stdout_logfile=/var/log/gunicorn/gunicorn.out.log

[group:guni]
    programs:gunicorn
SUP_GUN"

    echo -e "$(date +'%Y-%m-%d %R') Apply configuration."
    sudo supervisorctl reread # tell supervisor read configuration file
    sudo supervisorctl update # update supervisor configuration
    sudo supervisorctl reload # Restarted supervisord
    sudo supervisorctl status # verify configuration status

    # read -p "Press Enter to continue..."
}

# Install and configure firewall
setup_firewall() {
    echo -e "\n$(date +'%Y-%m-%d %R') Installing Firwall..."
    sudo apt-get install ufw # install firewall
    echo $(date +'%Y-%m-%d %R') Firwall installed.

    echo -e "\n$(date +'%Y-%m-%d %R') Configure Firwall"
    sudo ufw default allow outgoing # Allow outgoing traffic
    sudo ufw default deny incoming  # Deny all incoming traffic
    sudo ufw allow ssh              # Allow ssh traffic
    sudo ufw allow 8000             # Allow the port 8000, the port to test django while configuring deployment
    yes | sudo ufw enable           # Enables firewall

    echo -e "\n$(date +'%Y-%m-%d %R') Firwall status:"
    sudo ufw status # Status of firewall

    echo -e "\n$(date +'%Y-%m-%d %R') List available app:"
    sudo ufw app list

    # read -p "Press Enter to continue..."
}
